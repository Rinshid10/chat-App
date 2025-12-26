const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const users = new Map();

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('join', (username) => {
    users.set(socket.id, username);
    console.log(`${username} joined the chat`);

    io.emit('message', {
      id: Date.now().toString(),
      username: 'System',
      text: `${username} joined the chat`,
      timestamp: new Date().toISOString(),
      isSystem: true
    });
  });

  socket.on('message', (data) => {
    const username = users.get(socket.id) || 'Anonymous';
    const message = {
      id: Date.now().toString(),
      username: username,
      text: data.text,
      timestamp: new Date().toISOString(),
      isSystem: false
    };

    console.log(`${username}: ${data.text}`);
    io.emit('message', message);
  });

  socket.on('disconnect', () => {
    const username = users.get(socket.id);
    if (username) {
      console.log(`${username} left the chat`);
      io.emit('message', {
        id: Date.now().toString(),
        username: 'System',
        text: `${username} left the chat`,
        timestamp: new Date().toISOString(),
        isSystem: true
      });
      users.delete(socket.id);
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Chat server running on port ${PORT}`);
});
