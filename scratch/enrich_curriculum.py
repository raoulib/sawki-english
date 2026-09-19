import os
import re

# Dictionnaire de questions complémentaires (Q4 et Q5) pour les 120 leçons
# structuré par niveau et index de leçon (1 à 20)

LESSONS_EXTRA = {
    'A0': {
        1: [
            """            QuizQuestion(
              id: 'a0_1_4',
              type: ExerciseType.translation,
              prompt: 'Traduisez en anglais américain : "Épelez votre nom, s\\'il vous plaît."',
              options: ['Spell your name, please.', 'Write your letter, please.', 'Say your name, please.', 'Call your name, please.'],
              correctAnswer: 'Spell your name, please.',
              explanationFr: '"To spell" est le verbe exact pour épeler lettre par lettre aux USA.',
            ),""",
            """            QuizQuestion(
              id: 'a0_1_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la question essentielle d\\'épellation :',
              scrambledWords: ['How', 'do', 'you', 'spell', 'that?'],
              correctAnswer: 'How do you spell that?',
              explanationFr: 'Expression indispensable aux États-Unis pour demander l\\'orthographe d\\'un nom.',
            ),"""
        ],
        2: [
            """            QuizQuestion(
              id: 'a0_2_4',
              type: ExerciseType.translation,
              prompt: 'Traduisez en format US : "Il est neuf heures et quart du matin."',
              options: ['It is nine fifteen AM.', 'It is quarter past nine morning.', 'It is nine and quarter.', 'It is fifteen after nine AM.'],
              correctAnswer: 'It is nine fifteen AM.',
              explanationFr: 'Les Américains privilégient l\\'affichage direct "Nine fifteen AM" pour 9h15.',
            ),""",
            """            QuizQuestion(
              id: 'a0_2_5',
              type: ExerciseType.multipleChoice,
              prompt: 'Comment s\\'écrit la date "4 Juillet 2026" aux USA ?',
              options: ['July 4, 2026', '4 July 2026', '4/July/2026', 'Day 4 of July 2026'],
              correctAnswer: 'July 4, 2026',
              explanationFr: 'Aux États-Unis, le mois s\\'écrit TOUJOURS avant le jour (MM/DD/YYYY).',
            ),"""
        ],
        3: [
            """            QuizQuestion(
              id: 'a0_3_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Complétez : "Can you hear ___?"',
              options: ['us', 'we', 'our', 'they'],
              correctAnswer: 'us',
              explanationFr: 'Après un verbe, on emploie le pronom objet ("us", pas "we").',
            ),""",
            """            QuizQuestion(
              id: 'a0_3_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la phrase avec le pronom objet :',
              scrambledWords: ['I', 'see', 'them', 'every', 'morning.'],
              correctAnswer: 'I see them every morning.',
              explanationFr: '"Them" remplace "eux/elles" en position de complément d\\'objet.',
            ),"""
        ],
        4: [
            """            QuizQuestion(
              id: 'a0_4_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Quelle est la contraction américaine de "They are" ?',
              options: ['They\\'re', 'Their', 'There', 'Theyre'],
              correctAnswer: 'They\\'re',
              explanationFr: 'They are se contracte en They\\'re (se prononce souvent comme "there").',
            ),""",
            """            QuizQuestion(
              id: 'a0_4_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la phrase affirmative au présent :',
              scrambledWords: ['We', 'are', 'ready', 'for', 'class.'],
              correctAnswer: 'We are ready for class.',
              explanationFr: 'We s\\'accorde toujours avec l\\'auxiliaire "are".',
            ),"""
        ],
        5: [
            """            QuizQuestion(
              id: 'a0_5_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Quelle forme de "To Have" s\\'utilise avec "My brother" ?',
              options: ['has', 'have', 'haves', 'having'],
              correctAnswer: 'has',
              explanationFr: 'My brother = He, donc 3ème personne du singulier = "has".',
            ),""",
            """            QuizQuestion(
              id: 'a0_5_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la question américaine avec Do :',
              scrambledWords: ['Do', 'you', 'have', 'the', 'keys?'],
              correctAnswer: 'Do you have the keys?',
              explanationFr: 'Do + Sujet + have est la structure standard de question aux USA.',
            ),"""
        ],
        6: [
            """            QuizQuestion(
              id: 'a0_6_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Quelle formule dit-on quand on quitte quelqu\\'un pour la journée ?',
              options: ['Have a great day!', 'Good day sir.', 'Make a nice day.', 'Take your day.'],
              correctAnswer: 'Have a great day!',
              explanationFr: '"Have a great day!" ou "Have a good one!" est universel aux USA.',
            ),""",
            """            QuizQuestion(
              id: 'a0_6_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la salutation amicale de départ :',
              scrambledWords: ['See', 'you', 'later', 'my', 'friend!'],
              correctAnswer: 'See you later my friend!',
              explanationFr: '"See you later" équivaut à "À plus tard / À bientôt".',
            ),"""
        ],
        7: [
            """            QuizQuestion(
              id: 'a0_7_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Quelle est la contraction de "I would like" ?',
              options: ['I\\'d like', 'I\\'ll like', 'I\\'m like', 'I like'],
              correctAnswer: 'I\\'d like',
              explanationFr: '"I\\'d like" est la formule polie indispensable pour commander.',
            ),""",
            """            QuizQuestion(
              id: 'a0_7_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la commande américaine au café :',
              scrambledWords: ['Can', 'I', 'get', 'an', 'iced', 'coffee?'],
              correctAnswer: 'Can I get an iced coffee?',
              explanationFr: '"Can I get..." est la formule la plus naturelle dans les cafés américains.',
            ),"""
        ],
        8: [
            """            QuizQuestion(
              id: 'a0_8_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Que répond-on quand on s\\'excuse pour un petit incident ?',
              options: ['No worries!', 'It is nothing of all.', 'Never mind of it.', 'Do not think.'],
              correctAnswer: 'No worries!',
              explanationFr: '"No worries!" ou "You\\'re good!" est très courant aux USA.',
            ),""",
            """            QuizQuestion(
              id: 'a0_8_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la phrase de politesse :',
              scrambledWords: ['Pardon', 'me,', 'is', 'this', 'seat', 'taken?'],
              correctAnswer: 'Pardon me, is this seat taken?',
              explanationFr: '"Is this seat taken?" permet de demander si la place est libre.',
            ),"""
        ],
        9: [
            """            QuizQuestion(
              id: 'a0_9_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Comment appelle-t-on le mari de sa sœur en anglais ?',
              options: ['Brother-in-law', 'Step-brother', 'Cousin', 'Uncle'],
              correctAnswer: 'Brother-in-law',
              explanationFr: 'La belle-famille utilise le suffixe "-in-law" (par alliance).',
            ),""",
            """            QuizQuestion(
              id: 'a0_9_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la présentation familiale :',
              scrambledWords: ['This', 'is', 'my', 'younger', 'sister.'],
              correctAnswer: 'This is my younger sister.',
              explanationFr: '"Younger sister" = petite sœur.',
            ),"""
        ],
        10: [
            """            QuizQuestion(
              id: 'a0_10_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Comment dit-on "Il pleut des cordes" en anglais familier ?',
              options: ['It is pouring.', 'It rains heavily cord.', 'Water falls down.', 'It drops hard.'],
              correctAnswer: 'It is pouring.',
              explanationFr: '"It is pouring" (ou "It\\'s pouring outside") signifie qu\\'il pleut à verse.',
            ),""",
            """            QuizQuestion(
              id: 'a0_10_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la phrase météo :',
              scrambledWords: ['The', 'weather', 'is', 'sunny', 'and', 'warm.'],
              correctAnswer: 'The weather is sunny and warm.',
              explanationFr: 'Sunny and warm = ensoleillé et doux.',
            ),"""
        ],
        11: [
            """            QuizQuestion(
              id: 'a0_11_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Comment dit-on "au coin de la rue" en anglais américain ?',
              options: ['Around the corner', 'At the road end', 'In the angle', 'Near the crossing'],
              correctAnswer: 'Around the corner',
              explanationFr: '"Just around the corner" = juste au coin de la rue.',
            ),""",
            """            QuizQuestion(
              id: 'a0_11_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la demande de direction :',
              scrambledWords: ['Where', 'is', 'the', 'nearest', 'subway', 'station?'],
              correctAnswer: 'Where is the nearest subway station?',
              explanationFr: '"Subway station" = station de métro aux États-Unis.',
            ),"""
        ],
        12: [
            """            QuizQuestion(
              id: 'a0_12_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Comment dit-on "faire les courses alimentaires" aux USA ?',
              options: ['Grocery shopping', 'Food purchasing', 'Supermarket run', 'Course making'],
              correctAnswer: 'Grocery shopping',
              explanationFr: '"Grocery shopping" est le terme officiel pour faire les courses de nourriture.',
            ),""",
            """            QuizQuestion(
              id: 'a0_12_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la question de prix :',
              scrambledWords: ['How', 'much', 'does', 'this', 'shirt', 'cost?'],
              correctAnswer: 'How much does this shirt cost?',
              explanationFr: '"How much does... cost?" ou "How much is...?" pour demander le prix.',
            ),"""
        ],
        13: [
            """            QuizQuestion(
              id: 'a0_13_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Comment appelle-t-on le salon dans une maison américaine ?',
              options: ['Living room', 'Saloon', 'Parlor', 'Sitting hall'],
              correctAnswer: 'Living room',
              explanationFr: '"Living room" est la pièce de vie principale aux États-Unis.',
            ),""",
            """            QuizQuestion(
              id: 'a0_13_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la phrase descriptive :',
              scrambledWords: ['My', 'apartment', 'has', 'two', 'bright', 'bedrooms.'],
              correctAnswer: 'My apartment has two bright bedrooms.',
              explanationFr: 'Deux chambres lumineuses = two bright bedrooms.',
            ),"""
        ],
        14: [
            """            QuizQuestion(
              id: 'a0_14_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Comment dit-on "se brosser les dents" ?',
              options: ['Brush my teeth', 'Clean my tooth', 'Wash my mouth', 'Rub my teeth'],
              correctAnswer: 'Brush my teeth',
              explanationFr: 'Pluriel irrégulier : one tooth -> two teeth.',
            ),""",
            """            QuizQuestion(
              id: 'a0_14_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la routine matinale :',
              scrambledWords: ['I', 'wake', 'up', 'at', 'seven', 'every', 'morning.'],
              correctAnswer: 'I wake up at seven every morning.',
              explanationFr: '"Wake up" = se réveiller.',
            ),"""
        ],
        15: [
            """            QuizQuestion(
              id: 'a0_15_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Comment s\\'appelle la profession de serveur de restaurant aux USA ?',
              options: ['Server', 'Garcon', 'Food deliverer', 'Table keeper'],
              correctAnswer: 'Server',
              explanationFr: 'Aux USA, le terme neutre et respectueux standard est "server".',
            ),""",
            """            QuizQuestion(
              id: 'a0_15_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la phrase professionnelle :',
              scrambledWords: ['She', 'works', 'as', 'a', 'software', 'engineer.'],
              correctAnswer: 'She works as a software engineer.',
              explanationFr: 'Ingénieure logicielle = software engineer.',
            ),"""
        ],
        16: [
            """            QuizQuestion(
              id: 'a0_16_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Comment dit-on "passer du temps avec des amis" ?',
              options: ['Hang out with friends', 'Pass time with pals', 'Stay together', 'Make party'],
              correctAnswer: 'Hang out with friends',
              explanationFr: '"To hang out" est l\\'expression américaine n°1 pour passer du bon temps.',
            ),""",
            """            QuizQuestion(
              id: 'a0_16_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez l\\'activité de loisir :',
              scrambledWords: ['I', 'love', 'listening', 'to', 'jazz', 'music.'],
              correctAnswer: 'I love listening to jazz music.',
              explanationFr: 'N\\'oubliez jamais la préposition "to" après "listen".',
            ),"""
        ],
        17: [
            """            QuizQuestion(
              id: 'a0_17_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Comment dit-on "avoir mal à la tête" ?',
              options: ['I have a headache.', 'My head is sick.', 'I feel head pain.', 'Head makes hurt.'],
              correctAnswer: 'I have a headache.',
              explanationFr: 'Le suffixe "-ache" s\\'associe à la partie du corps (headache, stomachache).',
            ),""",
            """            QuizQuestion(
              id: 'a0_17_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la phrase de santé :',
              scrambledWords: ['You', 'should', 'drink', 'water', 'and', 'rest.'],
              correctAnswer: 'You should drink water and rest.',
              explanationFr: '"You should" = tu devrais (conseil de santé).',
            ),"""
        ],
        18: [
            """            QuizQuestion(
              id: 'a0_18_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Comment dit-on "un vol sans escale" aux États-Unis ?',
              options: ['A direct non-stop flight', 'A straight plane', 'A continuous travel', 'A flight without stop'],
              correctAnswer: 'A direct non-stop flight',
              explanationFr: '"Non-stop flight" est le terme officiel dans tous les aéroports américains.',
            ),""",
            """            QuizQuestion(
              id: 'a0_18_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la question à l\\'aéroport :',
              scrambledWords: ['Where', 'is', 'the', 'baggage', 'claim', 'area?'],
              correctAnswer: 'Where is the baggage claim area?',
              explanationFr: '"Baggage claim" = zone de récupération des bagages.',
            ),"""
        ],
        19: [
            """            QuizQuestion(
              id: 'a0_19_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Comment dit-on "recharger son smartphone" ?',
              options: ['Charge my phone', 'Fill my phone with power', 'Electrify my mobile', 'Put energy in mobile'],
              correctAnswer: 'Charge my phone',
              explanationFr: '"To charge" est le verbe standard pour recharger un appareil.',
            ),""",
            """            QuizQuestion(
              id: 'a0_19_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la demande de connexion :',
              scrambledWords: ['What', 'is', 'the', 'Wi-Fi', 'password', 'here?'],
              correctAnswer: 'What is the Wi-Fi password here?',
              explanationFr: 'Question indispensable dans n\\'importe quel lieu public américain.',
            ),"""
        ],
        20: [
            """            QuizQuestion(
              id: 'a0_20_4',
              type: ExerciseType.multipleChoice,
              prompt: 'Complétez la synthèse : "We ___ to New York tomorrow."',
              options: ['are traveling', 'travels', 'is travel', 'be traveling'],
              correctAnswer: 'are traveling',
              explanationFr: 'Présent continu pour un plan futur confirmé avec "We".',
            ),""",
            """            QuizQuestion(
              id: 'a0_20_5',
              type: ExerciseType.sentenceBuilder,
              prompt: 'Reconstituez la phrase de célébration des fondations :',
              scrambledWords: ['I', 'am', 'proud', 'of', 'my', 'progress!'],
              correctAnswer: 'I am proud of my progress!',
              explanationFr: '"To be proud of" = être fier de ses progrès.',
            ),"""
        ],
    }
}

print("Données A0 prêtes.")
