graph TD
    A[1. Landing Zone Repo<br/>Owner: Cloud Platform] --> B[2. Network Fabric Repo<br/>Owner: NetSec Team]
    B --> C[3. Shared Infrastructure Repo<br/>Owner: Platform/SRE]
    C --> D[4. App IaC Repos<br/>Owner: App Squads]
    E[5. Reusable Modules Repo<br/>Owner: Platform/Security] -.->|Provides Versioned Blueprints to| D
    E -.->|Provides Versioned Blueprints to| C
