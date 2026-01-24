# Invoice Management Web

A Flutter project for invoice management.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Node.js**: Required to run the JSON server. [Install Node.js](https://nodejs.org/)

## Setup

1.  **Clone the repository** (if you haven't already):

    ```bash
    git clone <repository_url>
    cd invoice_management_web
    ```

2.  **Install Flutter dependencies**:

    ```bash
    flutter pub get
    ```

3.  **Install JSON Server**:
    Run the following command to install `json-server` globally via npm:
    ```bash
    npm install -g json-server
    ```

## Running the JSON Server

The application uses a local JSON server to mock the backend. You must start this server before running the app.

1.  Open a terminal.
2.  Navigate to the `server` directory:
    ```bash
    cd server
    ```
3.  Start the server watching `db.json`:
    ```bash
    json-server --watch server/db.json --host 0.0.0.0
    ```
    _Note: The `--host 0.0.0.0` flag ensures the server is accessible if testing on mobile devices or different network configurations, though standard usage often defaults to localhost. By default, it runs on port 3000._

## Running the Flutter App

To run the application in Google Chrome:

1.  Open a new terminal (keep the JSON server running in the other one).
2.  Navigate to the project root directory.
3.  Run the following command:
    ```bash
    flutter run -d chrome
    ```

This will launch the application in a Chrome browser instance.
