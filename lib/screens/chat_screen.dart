import 'dart:convert';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_gpt/data/api_key.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _openAI = OpenAI.instance.build(
    token: OPENAI_API_KEY,
    baseOption: HttpSetup(
      receiveTimeout: const Duration(
        seconds: 5,
      ),
    ),
    enableLog: true,
  );

  final ChatUser _currentUser =
      ChatUser(id: '1', firstName: 'User', lastName: 'User');

  final ChatUser _gptChatUser =
      ChatUser(id: '2', firstName: 'Chat', lastName: 'GPT');

  List<ChatMessage> _messages = <ChatMessage>[];
  final List<ChatUser> _typingUsers = <ChatUser>[];

  @override
  void initState() {
    super.initState();
    loadChatHistory(); // Load chat history from phone memory
  }

  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat History'),
        content:
            const Text('Are you sure you want to delete the chat history?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              deleteChatHistory();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void deleteChatHistory() {
    setState(() {
      _messages.clear();
    });

    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('chat_history');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A67E),
        title: const Text(
          'GPT Chat',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.white,
            iconSize: 28,
            onPressed: () {
              showDeleteConfirmationDialog();
            },
          ),
        ],
      ),
      body: DashChat(
        currentUser: _currentUser,
        typingUsers: _typingUsers,
        messageOptions: const MessageOptions(
          currentUserContainerColor: Color(0xFF000000),
          containerColor: Color(0xFF00A67E),
          textColor: Colors.white,
        ),
        onSend: (ChatMessage m) {
          getChatResponse(m);
        },
        messages: _messages,
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async {
    // Check if the query is empty
    if (m.text.trim().isEmpty) {
      showErrorMessage('Query cannot be empty');
      return;
    }

    setState(() {
      _messages.insert(0, m);
      _typingUsers.add(_gptChatUser);
    });

    List<Messages> _messagesHistory = _messages.reversed.map((m) {
      if (m.user == _currentUser) {
        return Messages(role: Role.user, content: m.text);
      } else {
        return Messages(role: Role.assistant, content: m.text);
      }
    }).toList();

    final request = ChatCompleteText(
      model: GptTurbo0301ChatModel(),
      messages: _messagesHistory,
      maxToken: 200,
    );

    try {
      final response = await _openAI.onChatCompletion(request: request);

      if (response!.choices.isEmpty) {
        showErrorMessage('Empty response or error occurred');
      } else {
        for (var element in response.choices) {
          if (element.message != null) {
            setState(() {
              final newChatMessage = ChatMessage(
                user: _gptChatUser,
                createdAt: DateTime.now(),
                text: element.message!.content,
              );
              _messages.insert(0, newChatMessage);
            });
          }
        }
      }
    } catch (e) {
      showErrorMessage('An error occurred: $e');
    }

    setState(() {
      _typingUsers.remove(_gptChatUser);
    });

    saveChatHistory(); // Save chat history to phone memory
  }

  void showErrorMessage(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final chatHistory = prefs.getStringList('chat_history');
    if (chatHistory != null) {
      setState(() {
        _messages = chatHistory
            .map((json) => ChatMessage.fromJson(jsonDecode(json)))
            .toList()
            .reversed
            .toList();
      });
    }
  }

  Future<void> saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final chatHistory = _messages
        .map((message) => jsonEncode(message.toJson()))
        .toList()
        .reversed
        .toList();
    await prefs.setStringList('chat_history', chatHistory);
  }
}
