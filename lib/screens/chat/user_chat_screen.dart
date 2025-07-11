import '/constants/widgets.dart';
import '/screens/chat/chat_stream.dart';
import '/constants/colors.dart';
import '/provider/product_provider.dart';
import '/services/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserChatScreen extends StatefulWidget {
  static const String screenId = 'user_chat_screen';
  final String? chatroomId;
  const UserChatScreen({Key? key, this.chatroomId}) : super(key: key);

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  TextEditingController msgController = TextEditingController();
  UserService firebaseUser = UserService();

  bool send = false;

  @override
  void dispose() {
    msgController.dispose();
    super.dispose();
  }

  sendMessage() {
    if (msgController.text.isNotEmpty) {
      FocusScope.of(context).unfocus();
      Map<String, dynamic> message = {
        'message': msgController.text,
        'sent_by': firebaseUser.user!.uid,
        'time': DateTime.now().microsecondsSinceEpoch,
      };

      firebaseUser.createChat(chatroomId: widget.chatroomId, message: message);
      msgController.clear();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  _body() {
    return Container(
      child: Stack(
        children: [
          ChatStream(
            chatroomId: widget.chatroomId,
          ),
          Container(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: whiteColor,
                border: Border(
                  top: BorderSide(
                    color: disabledColor.withOpacity(0.2),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              send = true;
                            });
                          } else {
                            setState(() {
                              send = false;
                            });
                          }
                        },
                        onSubmitted: (value) {
                          /// Pressing Enter and Sending Message Case
                          if (value.isNotEmpty) {
                            sendMessage();
                          }
                        },
                        controller: msgController,
                        style: TextStyle(
                          color: blackColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter you message...',
                          hintStyle: TextStyle(
                            color: blackColor,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.attach_file),
                    ),
                    Visibility(
                      visible: send,
                      child: IconButton(
                        onPressed: sendMessage,
                        icon: const Icon(Icons.send),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var productProvider = Provider.of<ProductProvider>(context);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: whiteColor,
          elevation: 0,
          iconTheme: IconThemeData(color: blackColor),
          title: Text(
            'Chat Details',
            style: TextStyle(color: blackColor),
          ),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.call)),
            customPopUpMenu(
              context: context,
              chatroomId: widget.chatroomId,
            ),
          ],
        ),
        body: _body());
  }
}
