import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ppb_journey_app/models/trip_event.dart';
import 'package:ppb_journey_app/services/trip_service.dart';

class EditEventScreen extends StatefulWidget {
  final TripEvent trip;
  const EditEventScreen({super.key, required this.trip});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _destinationController;
  late TextEditingController _descriptionController;
  late TextEditingController _quotaController;
  
  File? _newSelectedImage;
  late DateTime _selectedDate;
  final TripService _tripService = TripService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.trip.title);
    _destinationController = TextEditingController(text: widget.trip.destination);
    _descriptionController = TextEditingController(text: widget.trip.description);
    _quotaController = TextEditingController(text: widget.trip.maxParticipants.toString());
    _selectedDate = widget.trip.startDate;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _newSelectedImage = File(pickedFile.path));
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _updateEvent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final updatedTrip = TripEvent(
          id: widget.trip.id,
          ownerId: widget.trip.ownerId,
          title: _titleController.text,
          destination: _destinationController.text,
          startDate: _selectedDate,
          description: _descriptionController.text,
          maxParticipants: int.parse(_quotaController.text),
          imageUrl: widget.trip.imageUrl,
        );

        await _tripService.updateTrip(updatedTrip, _newSelectedImage);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event berhasil diupdate!')));
          Navigator.pop(context, true); 
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_newSelectedImage != null) {
      imageProvider = FileImage(_newSelectedImage!);
    } else if (widget.trip.imageUrl != null) {
      imageProvider = NetworkImage(widget.trip.imageUrl!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity, height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null
                  ),
                  child: imageProvider == null ? const Center(child: Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey)) : null,
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text("Ketuk gambar untuk mengubah", style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 20),

              _buildInput(_titleController, 'Judul Event', Icons.title),
              const SizedBox(height: 16),
              _buildInput(_destinationController, 'Lokasi', Icons.location_on),
              const SizedBox(height: 16),
              _buildInput(_quotaController, 'Maksimal Peserta', Icons.people, type: TextInputType.number),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'Deskripsi', prefixIcon: const Icon(Icons.description, color: Colors.teal), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey[100]),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: Colors.teal),
                title: Text('Tanggal: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateEvent,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('UPDATE EVENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: ctrl, keyboardType: type,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: Colors.teal), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey[100]),
      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
    );
  }
}