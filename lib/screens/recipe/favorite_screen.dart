import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/widgets/recipe_widget.dart';


class FavoriteScreen extends StatefulWidget {
  final List<Recipe> favoritedRecipes;
  const FavoriteScreen({super.key, required this.favoritedRecipes});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top:20),
        child: ListView(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                 IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                    color: Colors.black,
                    iconSize: 20,
                  ),
                  Text(
                    'Favorites Recipe',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                   IconButton(
                    onPressed: () { 
                    },
                    icon: Icon( Icons.tune),
                    color: Colors.black,
                    iconSize: 25,
                  ),
                ],
              ),
            ),

            // Check if favorites list is empty

            widget.favoritedRecipes.isEmpty
                ? Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 230),
                        SizedBox(
                          height: 100,
                          child: Image.asset('assets/images/favorited.png'),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your favorited Recipes',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.favoritedRecipes.length,
                      itemBuilder: (BuildContext context, int index) {
                        return RecipeWidget(
                          index: index,
                          recipeScreenList: widget.favoritedRecipes, recipe: null,
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
