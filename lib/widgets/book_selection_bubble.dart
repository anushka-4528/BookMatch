import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/message_model.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class BookSuggestionBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;

  const BookSuggestionBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? metadata = message.metadata;
    final String bookTitle = metadata?['bookTitle'] ?? 'Unknown Book';
    final String author = metadata?['author'] ?? 'Unknown Author';
    final String? bookImageUrl = metadata?['bookImageUrl'];

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 250,
        margin: EdgeInsets.only(
          bottom: 12,
          left: isCurrentUser ? 50 : 0,
          right: isCurrentUser ? 0 : 50,
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5FF),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isCurrentUser ? const Radius.circular(20) : const Radius.circular(5),
                  bottomRight: isCurrentUser ? const Radius.circular(5) : const Radius.circular(20),
                ),
                border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.book_rounded,
                        size: 16,
                        color: AppTheme.primaryDarkColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Book Suggestion",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.primaryDarkColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[300],
                        ),
                        child: bookImageUrl != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: bookImageUrl,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.book,
                              size: 30,
                            ),
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Icon(
                          Icons.book,
                          size: 30,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bookTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              author,
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message.text,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimaryColor,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: EdgeInsets.only(
                left: isCurrentUser ? 0 : 12,
                right: isCurrentUser ? 12 : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('h:mm a').format(message.timestamp.toDate()),
                    style: AppTheme.captionStyle.copyWith(
                      fontSize: 10,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 12,
                      color: message.isRead ? Colors.blue : AppTheme.textSecondaryColor,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}