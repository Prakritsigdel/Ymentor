const mongoose = require('mongoose');

const CommentSchema = new mongoose.Schema(
  {
    senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    senderName: { type: String, default: 'User' },
    message: { type: String, required: true },
    createdAt: { type: Date, default: Date.now },
  },
  { _id: true }
);

const NoteSchema = new mongoose.Schema(
  {
    workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace', required: true },
    title: { type: String, required: true },
    description: { type: String, default: 'Assignment attached by mentor.' },
    dueDate: { type: String, default: 'Next Sunday, 11:59 PM' },
    pdfUrl: { type: String, required: true },
    uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    isCompleted: { type: Boolean, default: false },
    comments: { type: [CommentSchema], default: [] },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Note', NoteSchema);
