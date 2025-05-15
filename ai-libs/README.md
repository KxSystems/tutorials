# 🚀 ai-libs Tutorials
> **Note**: This tutorial is part of a beta release of software that is not yet publicly available. Please contact KX for access.

This folder contains concise, step-by-step tutorials designed to help developers quickly understand how to integrate kdb+ with AI/ML applications.

## 📖 Tutorials
1️⃣ Temporal Similarity Search (TSS) on NYSE trades
- Learn how to apply Temporal Similarity Search (TSS) on NYSE trade data to find patterns and trends in time series data.
- Conducting TSS with efficient by clauses to search for patterns like spikes, dips, or repeating trends.
- Analyzing multiple symbols and their time series patterns.

2️⃣ HNSW with Hacker News Embeddings
- Creating a kdb+ historical database (HDB) with Hacker News data and embeddings
- Building an HNSW index per partition for fast nearest neighbor searches
- Querying the database from both kdb+/q and Python using pykx

3️⃣ TSS on Partitioned Bitcoin Data
- Apply Temporal Similarity Search (TSS) across a partitioned kdb+ database filled with Bitcoin data.
- Efficient TSS query execution across partitions.
- Handling temporal pattern matches that span partition boundaries.

4️⃣ IVF with Wikipedia Embeddings 
- Learn how to use Inverted File Index (IVF) search on partitioned kdb+ databases containing Wikipedia embeddings.
- Partitioning data using K-Means clustering to improve search efficiency.
- Performing IVF searches and leveraging the ai-libs' flat functionality.

5️⃣ Combining Structured and Unstructured Data
-  Discover how to combine structured (Yahoo finance feed) and unstructured (SENS announcments) data
- Fetching Yahoo Finance ticker data using PyKX and creating embeddings with PyTorch on SENS data
- Integrating time series analysis with TSS and nearest neighbor searches with HNSW 
  
## 🤝 Join the Community!
Got questions? Want to connect with other kdb+ developers? Join our Slack community 👉 kx.com/slack