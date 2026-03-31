// Copyright (c) 2025 The ShardCoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <ai/ollama.h>
#include <logging.h>
#include <univalue.h>

#include <sstream>
#include <cstring>
#include <cerrno>

#ifdef WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32.lib")
typedef SOCKET socket_t;
#define CLOSE_SOCKET closesocket
#define SOCKET_ERROR_CODE WSAGetLastError()
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
typedef int socket_t;
#define INVALID_SOCKET -1
#define CLOSE_SOCKET close
#define SOCKET_ERROR_CODE errno
#endif

std::unique_ptr<OllamaClient> g_ollama;

OllamaClient::OllamaClient(const std::string& host, uint16_t port, int timeout_sec)
    : m_host(host), m_port(port), m_timeout_sec(timeout_sec) {}

std::string OllamaClient::DoHttp(const std::string& method, const std::string& path,
                                  const std::string& body)
{
    // Resolve host
    struct addrinfo hints{}, *res = nullptr;
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    std::string port_str = std::to_string(m_port);

    if (getaddrinfo(m_host.c_str(), port_str.c_str(), &hints, &res) != 0 || !res) {
        throw std::runtime_error("Ollama: failed to resolve " + m_host);
    }

    socket_t sock = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (sock == INVALID_SOCKET) {
        freeaddrinfo(res);
        throw std::runtime_error("Ollama: socket creation failed");
    }

    // Set timeouts
    struct timeval tv;
    tv.tv_sec = m_timeout_sec;
    tv.tv_usec = 0;
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (const char*)&tv, sizeof(tv));
    setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, (const char*)&tv, sizeof(tv));

    if (connect(sock, res->ai_addr, res->ai_addrlen) != 0) {
        CLOSE_SOCKET(sock);
        freeaddrinfo(res);
        throw std::runtime_error("Ollama: connection to " + m_host + ":" + port_str + " failed");
    }
    freeaddrinfo(res);

    // Build HTTP request
    std::ostringstream req;
    req << method << " " << path << " HTTP/1.1\r\n";
    req << "Host: " << m_host << ":" << m_port << "\r\n";
    req << "Connection: close\r\n";
    if (!body.empty()) {
        req << "Content-Type: application/json\r\n";
        req << "Content-Length: " << body.size() << "\r\n";
    }
    req << "\r\n";
    if (!body.empty()) {
        req << body;
    }

    std::string request_str = req.str();
    size_t sent = 0;
    while (sent < request_str.size()) {
        ssize_t n = send(sock, request_str.c_str() + sent, request_str.size() - sent, 0);
        if (n <= 0) {
            CLOSE_SOCKET(sock);
            throw std::runtime_error("Ollama: send failed");
        }
        sent += n;
    }

    // Read response
    std::string response;
    char buf[4096];
    while (true) {
        ssize_t n = recv(sock, buf, sizeof(buf), 0);
        if (n < 0) {
            CLOSE_SOCKET(sock);
            throw std::runtime_error("Ollama: recv failed (timeout or error)");
        }
        if (n == 0) break;
        response.append(buf, n);
    }

    CLOSE_SOCKET(sock);

    // Parse HTTP response: skip headers
    size_t header_end = response.find("\r\n\r\n");
    if (header_end == std::string::npos) {
        throw std::runtime_error("Ollama: malformed HTTP response");
    }

    return response.substr(header_end + 4);
}

OllamaResult OllamaClient::Generate(const std::string& model, const std::string& prompt)
{
    OllamaResult result;

    try {
        UniValue req_body(UniValue::VOBJ);
        req_body.pushKV("model", model);
        req_body.pushKV("prompt", prompt);
        req_body.pushKV("stream", false);

        std::string body = DoHttp("POST", "/api/generate", req_body.write());

        UniValue resp(UniValue::VOBJ);
        if (!resp.read(body)) {
            // Ollama may return streamed JSON lines even with stream:false in some versions.
            // Try to find the last complete JSON object.
            size_t last_brace = body.rfind('}');
            if (last_brace != std::string::npos) {
                size_t obj_start = body.rfind('{', last_brace);
                if (obj_start != std::string::npos) {
                    std::string last_obj = body.substr(obj_start, last_brace - obj_start + 1);
                    if (!resp.read(last_obj)) {
                        result.error = "Failed to parse Ollama response";
                        return result;
                    }
                }
            } else {
                result.error = "Failed to parse Ollama response";
                return result;
            }
        }

        if (resp.exists("error")) {
            result.error = resp["error"].get_str();
            return result;
        }

        result.success = true;
        result.response = resp["response"].get_str();
        result.model = resp.exists("model") ? resp["model"].get_str() : model;
        if (resp.exists("total_duration"))
            result.total_duration = resp["total_duration"].get_int64();
        if (resp.exists("eval_count"))
            result.eval_count = resp["eval_count"].get_int64();

    } catch (const std::exception& e) {
        result.error = std::string("Ollama generate failed: ") + e.what();
    }

    return result;
}

bool OllamaClient::Ping()
{
    try {
        DoHttp("GET", "/");
        return true;
    } catch (...) {
        return false;
    }
}

std::vector<std::string> OllamaClient::ListModels()
{
    std::vector<std::string> models;
    try {
        std::string body = DoHttp("GET", "/api/tags");
        UniValue resp(UniValue::VOBJ);
        if (!resp.read(body)) return models;

        if (resp.exists("models")) {
            const UniValue& arr = resp["models"];
            for (size_t i = 0; i < arr.size(); ++i) {
                if (arr[i].exists("name")) {
                    models.push_back(arr[i]["name"].get_str());
                }
            }
        }
    } catch (const std::exception& e) {
        LogPrintf("Ollama: ListModels failed: %s\n", e.what());
    }
    return models;
}
