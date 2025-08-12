import 'package:amazon_clone_tutorial/common/widgets/loader.dart';
import 'package:amazon_clone_tutorial/constants/global_variables.dart';
import 'package:amazon_clone_tutorial/features/account/services/account_services.dart';

import 'package:amazon_clone_tutorial/features/order_details/screens/order_details.dart';
import 'package:amazon_clone_tutorial/models/order.dart';
import 'package:flutter/material.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  List<Order>? orders;
  final AccountServices accountServices = AccountServices();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fetchedOrders = await accountServices.fetchMyOrders(
        context: context,
      );
      if (!mounted) return;
      setState(() {
        orders = fetchedOrders;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load orders';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Loader();
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (orders == null || orders!.isEmpty) {
      return const Center(child: Text('No orders found.'));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to a full orders page
                },
                child: Text(
                  'See all',
                  style: TextStyle(color: GlobalVariables.selectedNavBarColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders!.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final order = orders![index];
              final product = order.products.isNotEmpty
                  ? order.products[0]
                  : null;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 0,
                ),
                leading: product != null
                    ? Image.network(
                        product.images[0],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_not_supported),
                        semanticLabel: '${product.name} image',
                      )
                    : const Icon(Icons.shopping_bag),
                title: Text(
                  product?.name ?? 'Unnamed product',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('Status: ${_statusText(order.status)}'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    OrderDetailScreen.routeName,
                    arguments: order,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _statusText(int status) {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Confirmed';
      case 2:
        return 'Shipped';
      case 4:
        return 'Delivered';
      default:
        return 'Unknown';
    }
  }
}
