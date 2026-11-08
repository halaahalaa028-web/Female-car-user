import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HatlyAndEpatlyButtons extends StatelessWidget {
  final VoidCallback onHatlyPressed;
  final VoidCallback onEpatlyPressed;
  const HatlyAndEpatlyButtons(
      {super.key, required this.onHatlyPressed, required this.onEpatlyPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: CustomHatlyEpatlyButtonWidget(
            onPressed: onHatlyPressed,
            child: Text('hatly'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: CustomHatlyEpatlyButtonWidget(
            onPressed: onEpatlyPressed,
            child: Text('epatly'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class CustomHatlyEpatlyButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const CustomHatlyEpatlyButtonWidget({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        // backgroundColor: Theme.of(context)./.withValues(alpha: 0.1),
        // foregroundColor: Theme.of(context).primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
        ),
      ),
      child: child,
    );
  }
}
