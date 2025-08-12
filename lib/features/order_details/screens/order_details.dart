import 'package:amazon_clone_tutorial/common/widgets/custom_button.dart';
import 'package:amazon_clone_tutorial/constants/global_variables.dart';
import 'package:amazon_clone_tutorial/features/admin/services/admin_services.dart';
import 'package:amazon_clone_tutorial/features/search/screens/search_screen.dart';
import 'package:amazon_clone_tutorial/models/order.dart';
import 'package:amazon_clone_tutorial/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OrderDetailScreen extends StatefulWidget {
  static const String routeName = '/order-details';
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late int currentStep;
  final AdminServices adminServices = AdminServices();

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Ensure step is within valid bounds (0..3)
    currentStep = widget.order.status.clamp(0, 3);
  }

  void navigateToSearchScreen(String query) {
    Navigator.pushNamed(context, SearchScreen.routeName, arguments: query);
  }

  Future<bool?> _confirmAdvance() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm status change'),
        content: const Text(
          'Move this order to the next stage? This action can be recorded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Only for admin
  Future<void> changeOrderStatus(int stepIndex) async {
    final confirmed = await _confirmAdvance();
    if (confirmed != true) return;

    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    if (!mounted) return;

    // adminServices.changeOrderStatus signature in your codebase expects onSuccess callback.
    // We'll pass an onSuccess that updates local state and shows feedback.
    try {
      adminServices.changeOrderStatus(
        context: context,
        status: stepIndex + 1, // service expects 1-based status
        order: widget.order,
        onSuccess: () {
          if (!mounted) return;
          // update local UI only after server acknowledges
          setState(() {
            currentStep = (stepIndex + 1).clamp(0, 3);
            _isUpdating = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order status updated successfully')),
          );
        },
      );

      // If changeOrderStatus does not call onSuccess on failure, consider adding an onError in service.
      // We rely on the service to call onSuccess or show error messages via context.
    } catch (e) {
      if (!mounted) return;
      // Defensive fallback if the service throws
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status: $e')),
      );
    }
  }

  String _formatDate(int millis) {
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(millis);
      return DateFormat.yMMMMd().add_jm().format(dt);
    } catch (_) {
      return 'Unknown';
    }
  }

  String _formatCurrency(double value) {
    final f = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return f.format(value);
  }

  Widget _productRow(BuildContext context, int index) {
    final product = widget.order.products[index];
    final qty = widget.order.quantity[index];

    return InkWell(
      onTap: () => navigateToSearchScreen(product.name),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Row(
          children: [
            // Responsive thumbnail
            LayoutBuilder(
              builder: (context, constraints) {
                final thumbSize = (constraints.maxWidth < 400) ? 80.0 : 120.0;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: thumbSize,
                    width: thumbSize,
                    child: Image.network(
                      product.images.isNotEmpty ? product.images[0] : '',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          alignment: Alignment.center,
                          color: Colors.grey[100],
                          child: const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[100],
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image,
                            size: 36,
                            color: Colors.black26,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text('Qty: $qty'),
                  const SizedBox(height: 6),
                  Text(
                    _formatCurrency(product.price.toDouble()),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    // Price breakdown (you can adjust to use taxes/shipping from your Order model)
    final subtotal = widget
        .order
        .totalPrice; // assume totalPrice includes everything; replace if you have breakdown
    final shipping = 0.0;
    final tax = 0.0;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: GlobalVariables.appBarGradient,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  margin: const EdgeInsets.only(left: 6),
                  child: Material(
                    borderRadius: BorderRadius.circular(7),
                    elevation: 1,
                    child: TextFormField(
                      onFieldSubmitted: navigateToSearchScreen,
                      decoration: InputDecoration(
                        prefixIcon: InkWell(
                          onTap: () {},
                          child: const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.search,
                              color: Colors.black,
                              size: 23,
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.only(top: 10),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(7)),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(7),
                          ),
                          borderSide: BorderSide(
                            color: Colors.black38,
                            width: 1,
                          ),
                        ),
                        hintText: 'Search',
                        hintStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                color: Colors.transparent,
                height: 42,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: const Icon(Icons.mic, color: Colors.black, size: 25),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Optionally: re-fetch order details from server
          // For now just a tiny delay to show refresh behavior
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'View order details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Summary card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order ID: ${widget.order.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Placed: ${_formatDate(widget.order.orderedAt)}',
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Text(
                                    'Status: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  _buildStatusBadge(currentStep),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatCurrency(widget.order.totalPrice),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 120,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: link to invoice or download
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invoice not implemented'),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.picture_as_pdf,
                                  size: 18,
                                ),
                                label: const Text('Invoice'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Text(
                  'Purchase Details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < widget.order.products.length; i++)
                        _productRow(context, i),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                // Price breakdown
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildPriceRow('Subtotal', _formatCurrency(subtotal)),
                        const SizedBox(height: 6),
                        _buildPriceRow('Shipping', _formatCurrency(shipping)),
                        const SizedBox(height: 6),
                        _buildPriceRow('Tax', _formatCurrency(tax)),
                        const Divider(height: 16),
                        _buildPriceRow(
                          'Total',
                          _formatCurrency(subtotal + shipping + tax),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Text(
                  'Tracking',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Stepper(
                      physics: const ClampingScrollPhysics(),
                      currentStep: currentStep,
                      controlsBuilder: (context, details) {
                        if (user.type == 'admin') {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: SizedBox(
                              height: 44,
                              child: CustomButton(
                                text: _isUpdating
                                    ? 'Updating...'
                                    : (currentStep >= 3
                                          ? 'Completed'
                                          : 'Advance'),
                                onTap: () {
                                  changeOrderStatus(details.currentStep);
                                },
                              ),
                            ),
                          );
                        }
                        // Non-admins get no controls here
                        return const SizedBox.shrink();
                      },
                      steps: [
                        Step(
                          title: const Text('Pending'),
                          content: const Text(
                            'Your order has been placed and is awaiting processing.',
                          ),
                          isActive: currentStep >= 0,
                          state: currentStep > 0
                              ? StepState.complete
                              : (currentStep == 0
                                    ? StepState.editing
                                    : StepState.indexed),
                        ),
                        Step(
                          title: const Text('Confirmed'),
                          content: const Text(
                            'The store confirmed your order and is preparing it.',
                          ),
                          isActive: currentStep >= 1,
                          state: currentStep > 1
                              ? StepState.complete
                              : (currentStep == 1
                                    ? StepState.editing
                                    : StepState.indexed),
                        ),
                        Step(
                          title: const Text('Shipped'),
                          content: const Text(
                            'Your order is on the way to the delivery address.',
                          ),
                          isActive: currentStep >= 2,
                          state: currentStep > 2
                              ? StepState.complete
                              : (currentStep == 2
                                    ? StepState.editing
                                    : StepState.indexed),
                        ),
                        Step(
                          title: const Text('Delivered'),
                          content: const Text(
                            'Transaction completed. Thank you!',
                          ),
                          isActive: currentStep >= 3,
                          state: currentStep >= 3
                              ? StepState.complete
                              : StepState.indexed,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Optional actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // If you have tracking URL in order model use it
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tracking link not implemented'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.local_shipping),
                      label: const Text('Track Package'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Quick contact support example
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contact support (not implemented)'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Contact Support'),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(int step) {
    // Map step to human readable label/color
    final map = [
      {'label': 'Pending', 'color': Colors.orange},
      {'label': 'Confirmed', 'color': Colors.blue},
      {'label': 'Shipped', 'color': Colors.purple},
      {'label': 'Delivered', 'color': Colors.green},
    ];

    final item = map[step.clamp(0, map.length - 1)];
    return Container(
      decoration: BoxDecoration(
        color: (item['color'] as Color).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: item['color'] as Color),
          const SizedBox(width: 8),
          Text(
            item['label'] as String,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
