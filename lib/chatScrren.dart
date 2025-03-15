import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatScreen extends StatefulWidget {
  final String sender;
  final String receiver;

  ChatScreen({required this.sender, required this.receiver});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  void sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    String messageText = _messageController.text.trim();
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    Map<String, String> messageData = {
      "text": messageText,
      "timestamp": timestamp,
      "sender": widget.sender, // Store sender info
    };

    _dbRef.child("chats/${widget.sender}/${widget.receiver}/$timestamp").set(messageData);
    _dbRef.child("chats/${widget.receiver}/${widget.sender}/$timestamp").set(messageData);

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.receiver}"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _dbRef.child("chats/${widget.sender}/${widget.receiver}").onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return Center(child: Text("No messages yet"));
                }

                Map<dynamic, dynamic> messagesMap =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<MapEntry<dynamic, dynamic>> messagesList =
                    messagesMap.entries.toList();
                messagesList.sort((a, b) => a.key.compareTo(b.key));

                return ListView.builder(
                  itemCount: messagesList.length,
                  itemBuilder: (context, index) {
                    var message = messagesList[index].value;
                    bool isMe = widget.sender == message["sender"]; // Check sender

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, // Align sent messages right
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green.shade200 : Colors.blue.shade300, // Different colors
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message["text"] ?? "No message", // Handle null values
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatTimestamp(message["timestamp"] ?? "0"),
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.green),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    return "${date.hour}:${date.minute}";
  }
}
