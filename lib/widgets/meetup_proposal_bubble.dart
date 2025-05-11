import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../utils/theme.dart';

class MeetupProposalBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final ChatService chatService;
  final String currentUserId;
  final String receiverId;

  const MeetupProposalBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.chatService,
    required this.currentUserId,
    required this.receiverId,
  }) : super(key: key);

  @override
  State<MeetupProposalBubble> createState() => _MeetupProposalBubbleState();
}

class _MeetupProposalBubbleState extends State<MeetupProposalBubble> {
  bool _isResponding = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedLocation;
  final TextEditingController _locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    bool hasResponse = widget.message.metadata != null &&
        widget.message.metadata!.containsKey('response');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: widget.isMe ? AppTheme.primaryColor.withOpacity(0.9) : Colors.white,
            borderRadius: BorderRadius.circular(18.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3.0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: widget.isMe ? Colors.white : AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Meetup Proposal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.isMe ? Colors.white : AppTheme.primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.message.text,
                style: TextStyle(
                  color: widget.isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),

              // Show response if available
              if (hasResponse) ...[
                const Divider(thickness: 1),
                _buildResponseView(widget.message.metadata!['response']),
              ]
              // Show response buttons only if not the sender and no response yet
              else if (!widget.isMe && !hasResponse && !_isResponding) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildResponseButton(
                      'Accept',
                      Colors.green,
                          () => setState(() => _isResponding = true),
                    ),
                    const SizedBox(width: 10),
                    _buildResponseButton(
                      'Decline',
                      Colors.red,
                          () => _respondToProposal('declined', null, null, null),
                    ),
                  ],
                ),
              ],

              // Show form for accepting with details
              if (!widget.isMe && !hasResponse && _isResponding)
                _buildMeetupForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }

  Widget _buildMeetupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 20),
        const Text(
          'Schedule Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        // Date picker
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  style: TextStyle(
                    color: _selectedDate == null ? Colors.grey : Colors.black,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Time picker
        InkWell(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              setState(() {
                _selectedTime = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTime == null
                      ? 'Select Time'
                      : '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: _selectedTime == null ? Colors.grey : Colors.black,
                  ),
                ),
                const Icon(Icons.access_time, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Location input
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Meetup Location',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            setState(() {
              _selectedLocation = value;
            });
          },
        ),
        const SizedBox(height: 15),
        // Submit buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isResponding = false;
                  _selectedDate = null;
                  _selectedTime = null;
                  _locationController.clear();
                });
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _canSubmit()
                  ? () => _respondToProposal(
                'accepted',
                _selectedDate,
                _selectedTime,
                _locationController.text,
              )
                  : null,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ],
    );
  }

  bool _canSubmit() {
    return _selectedDate != null && _selectedTime != null &&
        _locationController.text.trim().isNotEmpty;
  }

  Widget _buildResponseView(Map<String, dynamic> response) {
    String status = response['status'];
    bool isAccepted = status == 'accepted';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isAccepted ? Icons.check_circle : Icons.cancel,
              color: isAccepted ? Colors.green : Colors.red,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              isAccepted ? 'Meetup Accepted' : 'Meetup Declined',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAccepted ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        if (isAccepted) ...[
          const SizedBox(height: 10),
          _buildDetailRow(Icons.calendar_today, 'Date', response['date']),
          _buildDetailRow(Icons.access_time, 'Time', response['time']),
          _buildDetailRow(Icons.location_on, 'Location', response['location']),
        ],
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: TextStyle(color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _respondToProposal(
      String status,
      DateTime? date,
      TimeOfDay? time,
      String? location,
      ) async {
    try {
      Map<String, dynamic> responseData = {
        'status': status,
      };

      if (status == 'accepted') {
        responseData.addAll({
          'date': '${date!.day}/${date.month}/${date.year}',
          'time': '${time!.hour}:${time.minute.toString().padLeft(2, '0')}',
          'location': location,
        });
      }

      await widget.chatService.respondToMeetupProposal(
        messageId: widget.message.id,
        senderId: widget.currentUserId,
        receiverId: widget.receiverId,
        response: responseData,
      );

      setState(() {
        _isResponding = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error responding to meetup: $e')),
      );
    }
  }
}