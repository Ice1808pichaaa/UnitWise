import 'package:flutter/material.dart';
import 'package:hackathon/models/app_drawer.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(3, 63, 99, 1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 16, color: Colors.black),
              children: [
                TextSpan(
                  text: "UnitWise: Scan the label. See the value.\n",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text:
                      "UnitWise is designed to help users make smarter shopping decisions "
                      "by comparing the price and value of grocery products, especially supplements.\n\n",
                ),
                TextSpan(
                  text: "Price Comparison Made Easy:\n",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text:
                      "The app automatically calculates cost per unit so you can clearly see the real value "
                      "behind each product.\n\n",
                ),
                TextSpan(
                  text: "Special Focus on Vitamins & Supplements:\n",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text:
                      "Since supplements can be difficult to compare, the app highlights "
                      "cost per serving and cost per milligram, making it easier to identify "
                      "which option provides better value.\n\n",
                ),
                TextSpan(
                  text: "Smart Recommendations:\n",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text:
                      "The app analyzes products side-by-side and suggests which one is "
                      "more worth it for your money.\n\n",
                ),
                TextSpan(
                  text: "Product History:\n",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text:
                      "You can save the products you decide to buy. Your history is stored "
                      "so you can revisit past decisions at any time.\n\n",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
