import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalorieCalculatorService {
  static Future<void> updateUserCalories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot profileDoc = await FirebaseFirestore.instance
            .collection('userProfiles')
            .doc(user.uid)
            .get();
            
      
        DocumentSnapshot goalDoc = await FirebaseFirestore.instance
            .collection('userGoals')
            .doc(user.uid)
            .get();
            
        if (profileDoc.exists && goalDoc.exists) {
          final profileData = profileDoc.data() as Map<String, dynamic>;
          final goalData = goalDoc.data() as Map<String, dynamic>;
          
         
          if (profileData.containsKey('weight') && 
              profileData.containsKey('height') && 
              profileData.containsKey('gender') && 
              profileData.containsKey('activity') && 
              profileData.containsKey('birthday') && 
              goalData.containsKey('goal')) {
              
          
            double weight = profileData['weight'] as double;
            double height = profileData['height'] as double;
            String gender = profileData['gender'] as String;
            String activity = profileData['activity'] as String;
            String goal = goalData['goal'] as String;
            
          
            DateTime birthday = DateTime.parse(profileData['birthday']);
            DateTime today = DateTime.now();
            int age = today.year - birthday.year;
            if (today.month < birthday.month || 
                (today.month == birthday.month && today.day < birthday.day)) {
              age--;
            }
            
           
            double bmr;
            if (gender == 'Male') {
              bmr = 10 * weight + 6.25 * height - 5 * age + 5;
            } else {
              bmr = 10 * weight + 6.25 * height - 5 * age - 161;
            }
            
           
            double activityMultiplier;
            switch (activity) {
              case 'Sedentary':
                activityMultiplier = 1.2;
                break;
              case 'Light':
                activityMultiplier = 1.375;
                break;
              case 'Moderate':
                activityMultiplier = 1.55;
                break;
              case 'Active':
                activityMultiplier = 1.725;
                break;
              default:
                activityMultiplier = 1.2;
            }
            
            double tdee = bmr * activityMultiplier;
            double caloriesPerDay;
            double proteinPercentage;
            double carbsPercentage;
            double fatPercentage;
            
            switch (goal) {
              case 'Lose Weight':
                caloriesPerDay = tdee * 0.8; 
                proteinPercentage = 0.35; 
                carbsPercentage = 0.35;   
                fatPercentage = 0.3;     
                break;
                
              case 'Build Muscle':
                caloriesPerDay = tdee * 1.1; 
                proteinPercentage = 0.4; 
                carbsPercentage = 0.4;   
                fatPercentage = 0.2;      
                break;
                
              case 'Balanced Diet':
                caloriesPerDay = tdee; 
                proteinPercentage = 0.3;
                carbsPercentage = 0.4;
                fatPercentage = 0.3;
                break;
                
              case 'Healthy Eating':
                caloriesPerDay = tdee; 
                proteinPercentage = 0.3;
                carbsPercentage = 0.45; 
                fatPercentage = 0.25;  
                break;
                
              default:
                caloriesPerDay = tdee;
                proteinPercentage = 0.3;
                carbsPercentage = 0.4;
                fatPercentage = 0.3;
            }
            
            
            double proteinGrams = (caloriesPerDay * proteinPercentage) / 4; 
            double carbsGrams = (caloriesPerDay * carbsPercentage) / 4; 
            double fatGrams = (caloriesPerDay * fatPercentage) / 9;
            
            await FirebaseFirestore.instance
                .collection('usersCaloriesMacronutrient')
                .doc(user.uid)
                .set({
                  'caloriesPerDay': caloriesPerDay,
                  'proteinGrams': proteinGrams,
                  'carbsGrams': carbsGrams,
                  'fatGrams': fatGrams,
                  'goal': goal,
                  'proteinPercentage': proteinPercentage,
                  'carbsPercentage': carbsPercentage,
                  'fatPercentage': fatPercentage,
                  'lastUpdated': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
                
           
            await FirebaseFirestore.instance
                .collection('usersCaloriesMacronutrient')
                .doc(user.uid)
                .update({
                  'history': FieldValue.arrayUnion([
                    {
                      'date': FieldValue.serverTimestamp(),
                      'caloriesPerDay': caloriesPerDay,
                      'proteinGrams': proteinGrams,
                      'carbsGrams': carbsGrams,
                      'fatGrams': fatGrams,
                    }
                  ]),
                });
                
            print('Calories updated successfully: $caloriesPerDay kcal');
          } else {
            print('Missing required user data for calorie calculation');
          }
        }
      } catch (e) {
        print('Error updating calories: $e');
      }
    }
  }
}