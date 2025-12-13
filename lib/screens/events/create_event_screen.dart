import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ppb_journey_app/services/trip_service.dart';
import 'package:intl/intl.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quotaController = TextEditingController(text: '10');
  
  File? _selectedImage;
  final TripService _tripService = TripService();
  
  DateTime? _startDate;
  DateTime? _endDate;
  
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
  }

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Tanggal Mulai dulu")));
      return;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!,
      firstDate: _startDate!,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate() && _startDate != null && _endDate != null) {
      setState(() => _isLoading = true);
      try {
        await _tripService.createNewTrip(
          title: _titleController.text,
          destination: _destinationController.text,
          startDate: _startDate!,
          endDate: _endDate!,
          imageFile: _selectedImage,
          description: _descriptionController.text,
          maxParticipants: int.parse(_quotaController.text),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event berhasil dibuat!')));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi tanggal event.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Event Baru')),
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
                    image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null
                  ),
                  child: _selectedImage == null ? const Center(child: Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey)) : null,
                ),
              ),
              const SizedBox(height: 20),
              
              _buildInputField(controller: _titleController, label: 'Judul Event', icon: Icons.title),
              const SizedBox(height: 16),
              _buildInputField(controller: _destinationController, label: 'Lokasi', icon: Icons.location_on),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDateSelector(
                      label: "Tanggal Mulai",
                      date: _startDate,
                      onTap: _pickStartDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateSelector(
                      label: "Tanggal Selesai",
                      date: _endDate,
                      onTap: _pickEndDate,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildInputField(controller: _quotaController, label: 'Maksimal Peserta', icon: Icons.people, inputType: TextInputType.number),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Singkat', prefixIcon: const Icon(Icons.description, color: Colors.teal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[100],
                ),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createEvent,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SIMPAN EVENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector({required String label, DateTime? date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  date != null ? DateFormat('dd/MM/yyyy').format(date) : "-",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller, keyboardType: inputType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: Colors.teal), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[100]),
      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
    );
  }
}