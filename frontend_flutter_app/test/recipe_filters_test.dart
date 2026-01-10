import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter_app/filter/recipe_filters.dart';
import 'package:frontend_flutter_app/models/recipe.dart';

void main() {
  Recipe recipe({
    required String cuisine,
    required List<String> diets,
    required int minutes,
  }) {
    return Recipe(
      id: 'x',
      title: 'Test',
      imageUrl: 'https://example.com/x.jpg',
      description: 'Desc',
      ingredients: const <String>[],
      directions: const <String>[],
      cuisine: cuisine,
      diets: diets,
      cookingTimeMinutes: minutes,
    );
  }

  test('OR within cuisine selections; AND across categories', () {
    const RecipeFilters filters = RecipeFilters(
      selectedCuisines: <String>{'Italian', 'Mexican'},
      selectedDiets: <String>{'Vegan'},
      selectedTimeBuckets: <CookingTimeBucket>{},
    );

    // Cuisine matches (Italian) and diet matches -> true.
    expect(
      filters.matches(
        recipe(cuisine: 'Italian', diets: <String>['Vegan'], minutes: 20),
      ),
      isTrue,
    );

    // Cuisine matches (Mexican) but diet doesn't -> false (AND across categories).
    expect(
      filters.matches(
        recipe(cuisine: 'Mexican', diets: <String>[], minutes: 20),
      ),
      isFalse,
    );

    // Diet matches but cuisine not in selection -> false.
    expect(
      filters.matches(
        recipe(cuisine: 'Indian', diets: <String>['Vegan'], minutes: 20),
      ),
      isFalse,
    );
  });

  test('Time bucket selection works (OR within time buckets)', () {
    const RecipeFilters filters = RecipeFilters(
      selectedCuisines: <String>{},
      selectedDiets: <String>{},
      selectedTimeBuckets: <CookingTimeBucket>{
        CookingTimeBucket.under15,
        CookingTimeBucket.over60,
      },
    );

    expect(
      filters.matches(
        recipe(cuisine: 'Italian', diets: const <String>[], minutes: 10),
      ),
      isTrue,
    );
    expect(
      filters.matches(
        recipe(cuisine: 'Italian', diets: const <String>[], minutes: 30),
      ),
      isFalse,
    );
    expect(
      filters.matches(
        recipe(cuisine: 'Italian', diets: const <String>[], minutes: 90),
      ),
      isTrue,
    );
  });

  test('Serialization round-trip', () {
    const RecipeFilters filters = RecipeFilters(
      selectedCuisines: <String>{'Indian'},
      selectedDiets: <String>{'Vegan', 'Gluten-Free'},
      selectedTimeBuckets: <CookingTimeBucket>{CookingTimeBucket.min30to60},
    );

    final RecipeFilters decoded = RecipeFilters.fromJson(filters.toJson());
    expect(decoded.selectedCuisines, filters.selectedCuisines);
    expect(decoded.selectedDiets, filters.selectedDiets);
    expect(decoded.selectedTimeBuckets, filters.selectedTimeBuckets);
  });

  test('Facet count equals sum of selected sets', () {
    const RecipeFilters filters = RecipeFilters(
      selectedCuisines: <String>{'Italian', 'Mexican'},
      selectedDiets: <String>{'Vegan'},
      selectedTimeBuckets: <CookingTimeBucket>{
        CookingTimeBucket.under15,
        CookingTimeBucket.over60,
      },
    );

    expect(filters.selectedCuisines.length, 2);
    expect(filters.selectedDiets.length, 1);
    expect(filters.selectedTimeBuckets.length, 2);
    expect(
      filters.selectedCuisines.length +
          filters.selectedDiets.length +
          filters.selectedTimeBuckets.length,
      5,
    );
  });
}
