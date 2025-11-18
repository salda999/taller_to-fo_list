const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory storage for simplicity (in production, use a database)
let tasks = [];
let processedRequests = new Map(); // Store idempotency keys

// Routes
app.get('/tasks', (req, res) => {
  res.json(tasks);
});

app.get('/tasks/:id', (req, res) => {
  const task = tasks.find(t => t.id === req.params.id);
  if (!task) {
    return res.status(404).json({ error: 'Task not found' });
  }
  res.json(task);
});

app.post('/tasks', (req, res) => {
  const { title, completed = false } = req.body;
  const idempotencyKey = req.headers['idempotency-key'];
  
  if (!title) {
    return res.status(400).json({ error: 'Title is required' });
  }

  // Check for idempotent request
  if (idempotencyKey && processedRequests.has(idempotencyKey)) {
    const existingResponse = processedRequests.get(idempotencyKey);
    return res.status(201).json(existingResponse);
  }

  const newTask = {
    id: uuidv4(),
    title,
    completed,
    updatedAt: new Date().toISOString(),
  };

  tasks.push(newTask);
  
  // Store the response for idempotency
  if (idempotencyKey) {
    processedRequests.set(idempotencyKey, newTask);
  }
  
  res.status(201).json(newTask);
});

app.put('/tasks/:id', (req, res) => {
  const taskIndex = tasks.findIndex(t => t.id === req.params.id);
  const idempotencyKey = req.headers['idempotency-key'];
  
  if (taskIndex === -1) {
    return res.status(404).json({ error: 'Task not found' });
  }

  // Check for idempotent request
  if (idempotencyKey && processedRequests.has(idempotencyKey)) {
    const existingResponse = processedRequests.get(idempotencyKey);
    return res.json(existingResponse);
  }

  const { title, completed } = req.body;
  if (title !== undefined) tasks[taskIndex].title = title;
  if (completed !== undefined) tasks[taskIndex].completed = completed;
  tasks[taskIndex].updatedAt = new Date().toISOString();

  // Store the response for idempotency
  if (idempotencyKey) {
    processedRequests.set(idempotencyKey, tasks[taskIndex]);
  }

  res.json(tasks[taskIndex]);
});

app.delete('/tasks/:id', (req, res) => {
  const taskIndex = tasks.findIndex(t => t.id === req.params.id);
  const idempotencyKey = req.headers['idempotency-key'];
  
  // Check for idempotent request - return success if already processed
  if (idempotencyKey && processedRequests.has(idempotencyKey)) {
    return res.status(204).send();
  }

  if (taskIndex === -1) {
    // Task already deleted or never existed, but still return success for idempotency
    if (idempotencyKey) {
      processedRequests.set(idempotencyKey, { deleted: true });
    }
    return res.status(204).send();
  }

  tasks.splice(taskIndex, 1);
  
  // Store the response for idempotency
  if (idempotencyKey) {
    processedRequests.set(idempotencyKey, { deleted: true });
  }
  
  res.status(204).send();
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});