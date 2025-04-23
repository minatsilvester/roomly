# Roomly 🎮⏳

Roomly is a **real-time interactive room system** built with **Phoenix LiveView**. Users can create and join rooms for various activities such as **playing games, synchronized music listening, chatting, and Pomodoro focus sessions**. The project is designed to be highly interactive, leveraging **LiveView, Presence tracking, and GenServer-based room management**.

---

## 🚀 Features

- **Dynamic Room Creation**: Users can create different types of rooms with customizable configurations.
- **Live Presence Tracking**: See who is in the room in real-time using Phoenix Presence.
- **Pomodoro Timer**: Start, track, and sync Pomodoro sessions for focus rooms.
- **Stateful Rooms**: Each room runs as a **GenServer** process under a **Dynamic Supervisor**.
- **Persistent User Sessions**: Player IDs are stored in `localStorage` for persistence across refreshes.

---

## 📌 Room Types

1. **Pomodoro Room** ⏳: Time-based focus sessions with work/break cycles.
2. **Chat Room** 💬: Simple real-time chat functionality.

---

## 📌 More Possible Room Types to build

1. **Game Room** 🎮: Multiplayer rooms for interactive games.
2. **Music Room** 🎵: Synchronized listening experience for groups.

---

## 🛠️ Tech Stack

- **Backend**: Elixir, Phoenix LiveView
- **Frontend**: Tailwind CSS
- **Database**: PostgreSQL

---

## 🔥 Getting Started

### 1️⃣ Installation
```sh
# Clone the repository
git clone https://github.com/yourusername/roomly.git
cd roomly

# Install dependencies
mix deps.get
npm install --prefix assets

# Setup database
mix ecto.setup

# Start the server
mix phx.server
```

### 2️⃣ Running the Application
Once the server is running, open your browser and go to:
```
http://localhost:4000
```

---

## ⚡ How It Works

### Joining a Room 🚪
- Click on **Join Room** to enter.
- Presence tracks who is inside in real-time.

### Pomodoro Timer ⏳
- Click **Start Timer** to begin the session.
- The timer cycles between work and break periods.
- Live updates ensure all users see the same countdown.

### Leaving a Room 🚶
- Click **Leave Room** to exit.
- Your presence is updated in real-time.

---

## 🏗️ Architecture

### Dynamic Supervisor + GenServer
- Each **room is a GenServer**, dynamically spawned under a **Supervisor**.
- **Registry** is used to track running rooms.
- **Presence** updates the active user list in real-time.

### LiveView Integration
- Room pages update **without refresh**.
- **Live events** trigger state changes, like starting the timer or joining a room.

---

## 📌 Roadmap
- [ ] 🎲 Add more room type integrations
- [ ] 🛑 Auto-stop rooms after inactivity
- [ ] 🏆 Leaderboard and stats tracking

---

## 🌎 Connect
💬 Have questions or suggestions? Feel free to reach out or open an issue!