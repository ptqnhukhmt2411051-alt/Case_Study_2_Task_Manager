
const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true
    },

    description: {
      type: String,
      default: ''
    },

    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },

    assignedTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },

    acceptedBy: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      }
    ],

    sharedWith: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      }
    ],

    status: {
      type: String,
      enum: ['todo', 'in_progress', 'completed'],
      default: 'todo'
    },

    priority: {
      type: String,
      enum: ['low', 'medium', 'high'],
      default: 'medium'
    },

    startDate: {
      type: Date,
      default: null
    },

    dueDate: {
      type: Date,
      default: null
    }
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model('Task', taskSchema);
