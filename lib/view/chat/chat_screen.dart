import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:echeque_mvp/core/constants/app_colors.dart';
import 'package:echeque_mvp/view/home/home_screen.dart';
import 'package:echeque_mvp/view/tracker/analytics_screen.dart';
import 'package:echeque_mvp/view/home/profile_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatMessage {
  final String sender;
  final String text;
  ChatMessage({required this.sender, required this.text});

  Map<String, dynamic> toMap() => {'sender': sender, 'text': text};
  factory ChatMessage.fromMap(Map map) =>
      ChatMessage(sender: map['sender'], text: map['text']);
}

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Box chatBox;
  List<ChatMessage> messages = [];
  TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late stt.SpeechToText _stt;
  bool _listening = false;
  bool _aiTyping = false;
  Timer? _typingTimer;
  int _typingPhase = 0; // 0..3 dots

  @override
  void initState() {
    super.initState();
    openHiveBox();
    _stt = stt.SpeechToText();
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }
    final available = await _stt.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          setState(() => _listening = false);
        }
      },
      onError: (e) {
        setState(() => _listening = false);
      },
    );
    if (!available) return;
    setState(() => _listening = true);
    await _stt.listen(
      onResult: (res) {
        final txt = res.recognizedWords.trim();
        if (txt.isEmpty) return;
        controller.text = txt;
        if (res.finalResult) {
          sendMessage(txt);
          controller.clear();
          _stt.stop();
          setState(() => _listening = false);
        }
      },
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 30),
      partialResults: true,
    );
  }

  @override
  void dispose() {
    try { _stt.stop(); } catch (_) {}
    _typingTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> openHiveBox() async {
    chatBox = await Hive.openBox('chatHistory');
    loadMessages();
    if (messages.isEmpty) {
      final greet = ChatMessage(
        sender: 'ai',
        text: "Hi, I'm Finbot. How can I help you with your finances today?",
      );
      messages.add(greet);
      chatBox.add(greet.toMap());
      setState(() {});
    }
  }

  void loadMessages() {
    messages = chatBox.values
        .map((msg) => ChatMessage.fromMap(Map<String, dynamic>.from(msg)))
        .toList();
    setState(() {});
  }

  Future<void> sendMessage(String text) async {
    final userMsg = ChatMessage(sender: 'user', text: text);
    messages.add(userMsg);
    chatBox.add(userMsg.toMap());
    setState(() {});
    _scrollToBottom();
    // Start typing indicator
    _startTyping();
    try {
      // Pass the explicit model name here to avoid 404
      final geminiResponse = await Gemini.instance.text(text);
      _stopTyping();
      final aiMsg = ChatMessage(
        sender: 'ai',
        text: geminiResponse?.output ?? 'No response from Gemini.',
      );
      messages.add(aiMsg);
      chatBox.add(aiMsg.toMap());
      setState(() {});
      _scrollToBottom();
    } catch (e) {
      _stopTyping();
      final errorMsg = ChatMessage(
        sender: 'ai',
        text: 'Sorry, something went wrong with Gemini API: $e',
      );
      messages.add(errorMsg);
      chatBox.add(errorMsg.toMap());
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color userBubble = AppColors.primaryBlue;
    final Color aiBubble = AppColors.blueBackground;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Finbot',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickChip(
                    label: 'Total Balance',
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () {
                      final userQ = ChatMessage(sender: 'user', text: 'What is my total account balance?');
                      messages.add(userQ);
                      chatBox.add(userQ.toMap());
                      final ai = ChatMessage(
                        sender: 'ai',
                        text: 'Your total balance is ₹12,000.00.\n\nBreakup:\n- Primary: ₹8,000\n- Savings: ₹4,000',
                      );
                      messages.add(ai);
                      chatBox.add(ai.toMap());
                      setState(() {});
                      _scrollToBottom();
                    },
                  ),
                  _QuickChip(
                    label: 'Show Statement',
                    icon: Icons.receipt_long,
                    onTap: () {
                      final userQ = ChatMessage(sender: 'user', text: 'Show my latest bank statement.');
                      messages.add(userQ);
                      chatBox.add(userQ.toMap());
                      final ai = ChatMessage(
                        sender: 'ai',
                        text: 'Last 5 entries:\n1) -₹4000 Expense (House)\n2) -₹200 Mobile Money\n3) +₹10000 Salary\n4) -₹150 Food & Drink\n5) -₹250 Travel',
                      );
                      messages.add(ai);
                      chatBox.add(ai.toMap());
                      setState(() {});
                      _scrollToBottom();
                    },
                  ),
                  _QuickChip(
                    label: 'Last 3 Transactions',
                    icon: Icons.history,
                    onTap: () {
                      final userQ = ChatMessage(sender: 'user', text: 'Show my last 3 transactions.');
                      messages.add(userQ);
                      chatBox.add(userQ.toMap());
                      final ai = ChatMessage(
                        sender: 'ai',
                        text: 'Last 3:\n-₹4000 Expense (Rent)\n-₹200 Mobile Money to +91...\n+₹10000 Salary',
                      );
                      messages.add(ai);
                      chatBox.add(ai.toMap());
                      setState(() {});
                      _scrollToBottom();
                    },
                  ),
                  _QuickChip(
                    label: 'Spending This Month',
                    icon: Icons.pie_chart_outline,
                    onTap: () {
                      final userQ = ChatMessage(sender: 'user', text: 'Summarize my spending for this month.');
                      messages.add(userQ);
                      chatBox.add(userQ.toMap());
                      final ai = ChatMessage(
                        sender: 'ai',
                        text: 'This month spending: ₹4,400.\nCategories:\n- House: ₹4,000\n- Food: ₹150\n- Travel: ₹250\n\nChart:\n██████████  House\n█          Food\n██         Travel',
                      );
                      messages.add(ai);
                      chatBox.add(ai.toMap());
                      setState(() {});
                      _scrollToBottom();
                    },
                  ),
                  _QuickChip(
                    label: 'Income vs Expense',
                    icon: Icons.trending_up,
                    onTap: () {
                      final userQ = ChatMessage(sender: 'user', text: 'Compare my income vs expenses for this month.');
                      messages.add(userQ);
                      chatBox.add(userQ.toMap());
                      final ai = ChatMessage(
                        sender: 'ai',
                        text: 'Income: ₹10,000\nExpense: ₹4,400\nNet: +₹5,600\n\nChart:\nIncome  ██████████\nExpense ████',
                      );
                      messages.add(ai);
                      chatBox.add(ai.toMap());
                      setState(() {});
                      _scrollToBottom();
                    },
                  ),
                  _QuickChip(
                    label: 'Show Categories',
                    icon: Icons.category_outlined,
                    onTap: () {
                      final userQ = ChatMessage(sender: 'user', text: 'Show my spending by category.');
                      messages.add(userQ);
                      chatBox.add(userQ.toMap());
                      final ai = ChatMessage(
                        sender: 'ai',
                        text: 'Categories this month:\n- House ₹4,000 (91%)\n- Food & Drink ₹150 (3%)\n- Travel ₹250 (6%)',
                      );
                      messages.add(ai);
                      chatBox.add(ai.toMap());
                      setState(() {});
                      _scrollToBottom();
                    },
                  ),
                  _QuickChip(
                    label: 'Set Budget',
                    icon: Icons.account_balance,
                    onTap: () {
                      final userQ = ChatMessage(sender: 'user', text: 'Help me set a monthly budget.');
                      messages.add(userQ);
                      chatBox.add(userQ.toMap());
                      final ai = ChatMessage(
                        sender: 'ai',
                        text: 'Suggested budget: ₹8,000 monthly.\nSplit:\n- Essentials ₹5,000\n- Discretionary ₹2,000\n- Savings ₹1,000',
                      );
                      messages.add(ai);
                      chatBox.add(ai.toMap());
                      setState(() {});
                      _scrollToBottom();
                    },
                  ),
                  _QuickChip(
                    label: 'Help',
                    icon: Icons.help_outline,
                    onTap: () {
                      final userQ = ChatMessage(sender: 'user', text: 'What can you do?');
                      messages.add(userQ);
                      chatBox.add(userQ.toMap());
                      final ai = ChatMessage(
                        sender: 'ai',
                        text: 'I can summarize your balances, recent transactions, category spend, and help with budgeting. Tap any chip above to try!',
                      );
                      messages.add(ai);
                      chatBox.add(ai.toMap());
                      setState(() {});
                      _scrollToBottom();
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: messages.length + (_aiTyping ? 1 : 0),
              itemBuilder: (context, idx) {
                if (_aiTyping && idx == messages.length) {
                  // Typing bubble on AI side
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
                      decoration: BoxDecoration(
                        color: aiBubble,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _TypingDots(phase: _typingPhase),
                    ),
                  );
                }
                bool isUser = messages[idx].sender == "user";
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.symmetric(vertical: 13, horizontal: 18),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? userBubble : aiBubble,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      messages[idx].text,
                      style: TextStyle(
                        fontSize: 16,
                        color: isUser ? Colors.white : AppColors.darkText,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: const Border(
                top: BorderSide(color: AppColors.grey200, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: const TextStyle(color: AppColors.grey600),
                      filled: true,
                      fillColor: AppColors.grey100,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.grey200,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.primaryBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        sendMessage(value.trim());
                        controller.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: _listening ? Colors.redAccent : AppColors.grey200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    tooltip: _listening ? 'Stop' : 'Speak',
                    icon: Icon(
                      _listening ? Icons.mic_off : Icons.mic,
                      color: _listening ? Colors.white : AppColors.darkText,
                    ),
                    onPressed: _toggleMic,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 26),
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        sendMessage(controller.text.trim());
                        controller.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.grey600,
        backgroundColor: AppColors.white,
        onTap: (idx) {
          if (idx == 1) return; // already on Chat
          switch (idx) {
            case 0:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
              break;
            case 2:
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
              break;
            case 3:
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _startTyping() {
    _typingTimer?.cancel();
    setState(() {
      _aiTyping = true;
      _typingPhase = 0;
    });
    _typingTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!_aiTyping) return;
      setState(() {
        _typingPhase = (_typingPhase + 1) % 4; // 0..3
      });
    });
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    setState(() {
      _aiTyping = false;
      _typingPhase = 0;
    });
  }
}

class _TypingDots extends StatelessWidget {
  final int phase; // 0..3
  const _TypingDots({required this.phase});

  @override
  Widget build(BuildContext context) {
    final active = Colors.black54;
    final inactive = Colors.black26;
    Color dot(int i) => (phase % 4) >= i ? active : inactive;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(dot(1)),
        const SizedBox(width: 4),
        _dot(dot(2)),
        const SizedBox(width: 4),
        _dot(dot(3)),
      ],
    );
  }

  Widget _dot(Color c) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.blueBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
