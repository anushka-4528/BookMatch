import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';
import '../services/user_service.dart';
import '../services/firebase_service.dart';

class MatchListItem extends StatelessWidget {
  final ChatModel chat;
  final UserModel matchedUser;
  final VoidCallback onTap;
  final Function(String) onUnmatch;

  const MatchListItem({
    Key? key,
    required this.chat,
    required this.matchedUser,
    required this.onTap,
    required this.onUnmatch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasUnreadMessages = chat.unreadCount > 0 &&
        chat.lastMessageSenderId != FirebaseService.currentUserId;

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onUnmatch(matchedUser.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.person_remove,
            label: 'Unmatch',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: hasUnreadMessages ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // User avatar with online indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primaryColor,
                    child: matchedUser.photoUrl != null
                        ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: matchedUser.photoUrl!,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.person),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Icon(Icons.person, size: 30, color: Colors.white),
                  ),
                  if (matchedUser.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.onlineColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // User info and last message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          matchedUser.name,
                          style: AppTheme.subheadingStyle.copyWith(
                            fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        Text(
                          chat.lastMessageTime != null
                              ? timeago.format(chat.lastMessageTime.toDate(), locale: 'en_short')
                              : '',
                          style: AppTheme.captionStyle.copyWith(
                            color: hasUnreadMessages ? AppTheme.primaryDarkColor : AppTheme.textSecondaryColor,
                            fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessageText ?? 'Start a conversation',
                            style: AppTheme.captionStyle.copyWith(
                              color: hasUnreadMessages ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
                              fontWeight: hasUnreadMessages ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnreadMessages)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryDarkColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              chat.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}