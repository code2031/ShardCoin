// Copyright (c) 2025 The ShardCoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef BITCOIN_AI_OLLAMA_H
#define BITCOIN_AI_OLLAMA_H

#include <cstdint>
#include <string>
#include <vector>
#include <memory>

/** Default Ollama API endpoint */
static const std::string DEFAULT_OLLAMA_HOST = "127.0.0.1";
static const uint16_t DEFAULT_OLLAMA_PORT = 11434;
static const std::string DEFAULT_OLLAMA_MODEL = "llama3.2:1b";
static const int DEFAULT_OLLAMA_TIMEOUT = 300; // seconds

/** Result of an Ollama generate request */
struct OllamaResult {
    bool success{false};
    std::string response;
    std::string model;
    std::string error;
    int64_t total_duration{0};   // nanoseconds
    int64_t eval_count{0};       // tokens generated
};

/**
 * HTTP client for the Ollama local AI inference API.
 * Communicates with Ollama over TCP sockets to localhost.
 */
class OllamaClient {
public:
    OllamaClient(const std::string& host = DEFAULT_OLLAMA_HOST,
                 uint16_t port = DEFAULT_OLLAMA_PORT,
                 int timeout_sec = DEFAULT_OLLAMA_TIMEOUT);

    /** Generate a completion from the given model and prompt. */
    OllamaResult Generate(const std::string& model, const std::string& prompt);

    /** Check if Ollama is reachable. */
    bool Ping();

    /** List available model names. */
    std::vector<std::string> ListModels();

private:
    std::string m_host;
    uint16_t m_port;
    int m_timeout_sec;

    /** Perform an HTTP request and return the response body. */
    std::string DoHttp(const std::string& method, const std::string& path,
                       const std::string& body = "");
};

/** Global Ollama client instance (initialized in init.cpp) */
extern std::unique_ptr<OllamaClient> g_ollama;

#endif // BITCOIN_AI_OLLAMA_H
