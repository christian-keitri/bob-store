import 'package:amazon_clone_tutorial/constants/utils.dart';
import 'package:amazon_clone_tutorial/features/address/services/address_services.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';
import 'package:provider/provider.dart';
import 'package:amazon_clone_tutorial/common/widgets/custom_textfield.dart';
import 'package:amazon_clone_tutorial/constants/global_variables.dart';
import 'package:amazon_clone_tutorial/providers/user_provider.dart';

class AddressScreen extends StatefulWidget {
  static const String routeName = '/address';
  final String totalAmount;

  const AddressScreen({super.key, required this.totalAmount});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final TextEditingController flatBuildingController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final _addressFormKey = GlobalKey<FormState>();

  String addressToBeUsed = "";
  List<PaymentItem> paymentItems = [];
  final AddressServices addressServices = AddressServices();

  PaymentConfiguration? _googlePayConfig;
  PaymentConfiguration? _applePayConfig;

  @override
  void initState() {
    super.initState();
    paymentItems.add(
      PaymentItem(
        amount: widget.totalAmount,
        label: 'Total Amount',
        status: PaymentItemStatus.final_price,
      ),
    );

    _loadPaymentConfigs();
  }

  Future<void> _loadPaymentConfigs() async {
    final googleConfig = await PaymentConfiguration.fromAsset('gpay.json');
    final appleConfig = await PaymentConfiguration.fromAsset('applepay.json');

    if (mounted) {
      setState(() {
        _googlePayConfig = googleConfig;
        _applePayConfig = appleConfig;
      });
    }
  }

  @override
  void dispose() {
    flatBuildingController.dispose();
    areaController.dispose();
    pincodeController.dispose();
    cityController.dispose();
    super.dispose();
  }

  void onApplePayResult(paymentResult) {
    final user = Provider.of<UserProvider>(context, listen: false).user;

    if (user.address.isEmpty) {
      addressServices.saveUserAddress(
        context: context,
        address: addressToBeUsed,
      );
    }

    addressServices.placeOrder(
      context: context,
      address: addressToBeUsed,
      totalSum: double.parse(widget.totalAmount),
    );
  }

  void onGooglePayResult(paymentResult) {
    final user = Provider.of<UserProvider>(context, listen: false).user;

    if (user.address.isEmpty) {
      addressServices.saveUserAddress(
        context: context,
        address: addressToBeUsed,
      );
    }

    addressServices.placeOrder(
      context: context,
      address: addressToBeUsed,
      totalSum: double.parse(widget.totalAmount),
    );
  }

  void payPressed(String addressFromProvider) {
    addressToBeUsed = "";

    bool isForm =
        flatBuildingController.text.isNotEmpty ||
        areaController.text.isNotEmpty ||
        pincodeController.text.isNotEmpty ||
        cityController.text.isNotEmpty;

    if (isForm) {
      if (_addressFormKey.currentState!.validate()) {
        addressToBeUsed =
            '${flatBuildingController.text}, ${areaController.text}, ${cityController.text} - ${pincodeController.text}';
      } else {
        showSnackBar(context, 'Please fill all fields');
        return;
      }
    } else if (addressFromProvider.isNotEmpty) {
      addressToBeUsed = addressFromProvider;
    } else {
      showSnackBar(context, 'Please enter your address.');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAddress = context.watch<UserProvider>().user.address;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: GlobalVariables.appBarGradient,
            ),
          ),
        ),
      ),
      body: _googlePayConfig == null || _applePayConfig == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    if (userAddress.isNotEmpty)
                      Column(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black12),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              userAddress,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('OR', style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 20),
                        ],
                      ),
                    Form(
                      key: _addressFormKey,
                      child: Column(
                        children: [
                          CustomTextfield(
                            controller: flatBuildingController,
                            hintText: 'Flat, House no, Building',
                          ),
                          const SizedBox(height: 10),
                          CustomTextfield(
                            controller: areaController,
                            hintText: 'Area, Street',
                          ),
                          const SizedBox(height: 10),
                          CustomTextfield(
                            controller: pincodeController,
                            hintText: 'Pincode',
                          ),
                          const SizedBox(height: 10),
                          CustomTextfield(
                            controller: cityController,
                            hintText: 'Town/City',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ApplePayButton(
                      paymentConfiguration: _applePayConfig!,
                      paymentItems: paymentItems,
                      type: ApplePayButtonType.buy,
                      margin: const EdgeInsets.only(top: 15),
                      height: 50,
                      onPaymentResult: onApplePayResult,
                      onPressed: () => payPressed(userAddress),
                    ),
                    const SizedBox(height: 10),
                    GooglePayButton(
                      paymentConfiguration: _googlePayConfig!,
                      paymentItems: paymentItems,
                      type: GooglePayButtonType.buy,
                      margin: const EdgeInsets.only(top: 15),
                      height: 50,
                      onPaymentResult: onGooglePayResult,
                      onPressed: () => payPressed(userAddress),
                      loadingIndicator: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
