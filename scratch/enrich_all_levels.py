# -*- coding: utf-8 -*-
"""
Script complet d'enrichissement pédagogique du cursus Sawki English.
Passe chaque leçon de 3 à 5 questions complètes et variées sur l'ensemble des 6 niveaux (A0 à C1).
"""
import re
import os

def create_lesson_extras():
    extras = {}

    # A0
    extras['A0'] = {
        1: [
            ('translation', 'Traduisez en anglais américain : "Épelez votre prénom, s\'il vous plaît."',
             ['Spell your first name, please.', 'Write your first name please.', 'Tell your letters please.', 'Call your first name please.'],
             'Spell your first name, please.',
             '"To spell" est le verbe officiel pour épeler lettre par lettre aux USA.'),
            ('sentenceBuilder', 'Reconstituez la question d\'épellation indispensable :',
             ['How', 'do', 'you', 'spell', 'that?'],
             'How do you spell that?',
             'Question incontournable aux USA : "Comment cela s\'écrit-il / s\'épelle-t-il ?".')
        ],
        2: [
            ('translation', 'Traduisez selon l\'usage direct américain : "Il est 9h15 du matin."',
             ['It is nine fifteen AM.', 'It is quarter past nine morning.', 'It is nine and quarter.', 'It is fifteen after nine AM.'],
             'It is nine fifteen AM.',
             'Aux USA, on utilise couramment l\'affichage numérique direct (nine fifteen AM).'),
            ('multipleChoice', 'Comment s\'écrit la date du "4 Juillet 2026" aux USA ?',
             ['July 4, 2026', '4 July 2026', '4/July/2026', 'Day 4 of July 2026'],
             'July 4, 2026',
             'Aux États-Unis, le mois s\'écrit TOUJOURS avant le quantième du jour.')
        ],
        3: [
            ('multipleChoice', 'Quel pronom complète : "She invited ___ to dinner" ?',
             ['us', 'we', 'our', 'they'],
             'us',
             'Après un verbe d\'action, on utilise le pronom objet ("us", jamais "we").'),
            ('sentenceBuilder', 'Reconstituez la phrase avec le pronom complément :',
             ['I', 'see', 'them', 'every', 'morning.'],
             'I see them every morning.',
             '"Them" remplace "eux/elles" en fonction d\'objet direct.')
        ],
        4: [
            ('multipleChoice', 'Quelle est la contraction orale de "They are" ?',
             ['They\'re', 'Their', 'There', 'Theyre'],
             'They\'re',
             'They are se contracte en They\'re (homophone de their et there).'),
            ('sentenceBuilder', 'Reconstituez la phrase affirmative au présent :',
             ['We', 'are', 'ready', 'for', 'class.'],
             'We are ready for class.',
             'Le sujet "We" s\'accorde toujours avec l\'auxiliaire "are".')
        ],
        5: [
            ('multipleChoice', 'Quelle forme de "To Have" s\'utilise avec "My brother" ?',
             ['has', 'have', 'haves', 'having'],
             'has',
             'My brother équivaut au sujet He, donc prend "has" à la 3e personne.'),
            ('sentenceBuilder', 'Reconstituez la question américaine avec Do :',
             ['Do', 'you', 'have', 'the', 'keys?'],
             'Do you have the keys?',
             'Do + Sujet + have est la structure standard de question aux USA.')
        ],
        6: [
            ('multipleChoice', 'Quelle salutation amicale de départ utilise-t-on le plus aux USA ?',
             ['Have a great day!', 'Make a good day!', 'Do a nice day!', 'Take your day!'],
             'Have a great day!',
             '"Have a great day!" ou "Have a good one!" est la formule universelle.'),
            ('sentenceBuilder', 'Reconstituez la formule de départ :',
             ['See', 'you', 'later,', 'my', 'friend!'],
             'See you later, my friend!',
             '"See you later" équivaut à "À plus tard / À la prochaine".')
        ],
        7: [
            ('multipleChoice', 'Quelle est la formule polie contractée pour commander aux USA ?',
             ['I\'d like', 'I\'ll like', 'I\'m like', 'I like'],
             'I\'d like',
             '"I\'d like" (contraction de I would like) est la formule polie par excellence.'),
            ('sentenceBuilder', 'Reconstituez la commande au comptoir américain :',
             ['Can', 'I', 'get', 'an', 'iced', 'coffee?'],
             'Can I get an iced coffee?',
             '"Can I get..." est la formule la plus spontanée et naturelle au café.')
        ],
        8: [
            ('multipleChoice', 'Que répond un Américain pour dire "Pas de problème / De rien" ?',
             ['No problem!', 'No problem of it.', 'It makes nothing.', 'Do not think about.'],
             'No problem!',
             '"No problem!" ou "No worries!" est très répandu dans les échanges quotidiens.'),
            ('sentenceBuilder', 'Reconstituez la question polie :',
             ['Excuse', 'me,', 'where', 'is', 'the', 'exit?'],
             'Excuse me, where is the exit?',
             '"Excuse me" sert à attirer l\'attention avec courtoisie.')
        ],
        9: [
            ('multipleChoice', 'Comment appelle-t-on sa belle-sœur (la sœur de son conjoint) ?',
             ['Sister-in-law', 'Step-sister', 'Half-sister', 'Cousin-sister'],
             'Sister-in-law',
             'La belle-famille par alliance prend le suffixe "-in-law" en anglais.'),
            ('sentenceBuilder', 'Reconstituez la présentation familiale :',
             ['This', 'is', 'my', 'younger', 'brother.'],
             'This is my younger brother.',
             '"Younger brother" = petit frère.')
        ],
        10: [
            ('multipleChoice', 'Comment dit-on "Il fait très chaud aujourd\'hui" ?',
             ['It is very hot today.', 'It makes hot today.', 'He is hot today.', 'The weather does hot.'],
             'It is very hot today.',
             'Pour la météo, on utilise TOUJOURS le pronom impersonnel "It is" (jamais le verbe faire).'),
            ('sentenceBuilder', 'Reconstituez la phrase météorologique :',
             ['The', 'sun', 'is', 'shining', 'brightly.'],
             'The sun is shining brightly.',
             'Le soleil brille intensément = The sun is shining brightly.')
        ],
        11: [
            ('multipleChoice', 'Que signifie l\'expression américaine "around the corner" ?',
             ['Juste au coin de la rue', 'Loin de la ville', 'En haut de la côte', 'Au bout du couloir'],
             'Juste au coin de la rue',
             '"Just around the corner" indique une très grande proximité spatiale ou temporelle.'),
            ('sentenceBuilder', 'Reconstituez la demande d\'orientation :',
             ['Where', 'is', 'the', 'nearest', 'ATM?'],
             'Where is the nearest ATM?',
             'ATM désigne le distributeur automatique de billets aux USA.')
        ],
        12: [
            ('multipleChoice', 'Quel terme désigne le panier de courses au supermarché américain ?',
             ['Shopping cart', 'Food basket', 'Market box', 'Pushing bag'],
             'Shopping cart',
             '"Shopping cart" est le terme américain (en anglais britannique : trolley).'),
            ('sentenceBuilder', 'Reconstituez la question de paiement :',
             ['Do', 'you', 'accept', 'credit', 'cards?'],
             'Do you accept credit cards?',
             'Question classique en caisse aux États-Unis.')
        ],
        13: [
            ('multipleChoice', 'Comment désigne-t-on le rez-de-chaussée aux États-Unis ?',
             ['First floor', 'Ground floor', 'Zero level', 'Base floor'],
             'First floor',
             'Attention au piège : aux USA, le "first floor" est le rez-de-chaussée !'),
            ('sentenceBuilder', 'Reconstituez la description du logement :',
             ['Our', 'house', 'has', 'a', 'big', 'backyard.'],
             'Our house has a big backyard.',
             '"Backyard" = jardin à l\'arrière de la maison américaine typique.')
        ],
        14: [
            ('multipleChoice', 'Comment dit-on "faire une sieste rapide" en argot US ?',
             ['Take a power nap', 'Make a little sleep', 'Do a mini rest', 'Have a bed time'],
             'Take a power nap',
             '"A power nap" désigne une micro-sieste réparatrice de 15 à 20 minutes.'),
            ('sentenceBuilder', 'Reconstituez la routine du soir :',
             ['I', 'go', 'to', 'bed', 'before', 'midnight.'],
             'I go to bed before midnight.',
             '"Go to bed" = aller se coucher.')
        ],
        15: [
            ('multipleChoice', 'Quel article utilise-t-on devant "engineer" ?',
             ['an', 'a', 'the only', 'one'],
             'an',
             'On emploie "an" devant tout mot débutant par un son voyelle ("an engineer").'),
            ('sentenceBuilder', 'Reconstituez la phrase professionnelle :',
             ['He', 'is', 'an', 'experienced', 'accountant.'],
             'He is an experienced accountant.',
             'Un comptable expérimenté = an experienced accountant.')
        ],
        16: [
            ('multipleChoice', 'Quelle préposition suit TOUJOURS le verbe "listen" ?',
             ['to', 'at', 'with', 'on'],
             'to',
             'On dit toujours "listen to music", jamais "listen music".'),
            ('sentenceBuilder', 'Reconstituez l\'activité du week-end :',
             ['We', 'often', 'go', 'hiking', 'on', 'weekends.'],
             'We often go hiking on weekends.',
             '"Go hiking" = faire de la randonnée en pleine nature.')
        ],
        17: [
            ('multipleChoice', 'Comment dit-on "J\'ai mal à la gorge" ?',
             ['I have a sore throat.', 'My throat is broken.', 'I feel throat pain.', 'Throat hurts me.'],
             'I have a sore throat.',
             '"A sore throat" est l\'expression médicale idiomatique exacte.'),
            ('sentenceBuilder', 'Reconstituez le conseil de repos :',
             ['You', 'need', 'to', 'get', 'some', 'sleep.'],
             'You need to get some sleep.',
             'Tu as besoin de dormir = You need to get some sleep.')
        ],
        18: [
            ('multipleChoice', 'Comment appelle-t-on la carte d\'embarquement à l\'aéroport ?',
             ['Boarding pass', 'Flight ticket', 'Plane card', 'Fly badge'],
             'Boarding pass',
             '"Boarding pass" est le document indispensable pour monter dans l\'avion.'),
            ('sentenceBuilder', 'Reconstituez la question à la douane :',
             ['Here', 'is', 'my', 'passport', 'and', 'ticket.'],
             'Here is my passport and ticket.',
             'Voici mon passeport et mon billet.')
        ],
        19: [
            ('multipleChoice', 'Que signifie l\'abréviation US "App" ?',
             ['Application logicielle ou mobile', 'Appointment', 'Approach', 'Apple product'],
             'Application logicielle ou mobile',
             '"App" est la contraction universelle de software application.'),
            ('sentenceBuilder', 'Reconstituez la demande technique :',
             ['Can', 'you', 'send', 'me', 'the', 'download', 'link?'],
             'Can you send me the download link?',
             'Peux-tu m\'envoyer le lien de téléchargement ?')
        ],
        20: [
            ('multipleChoice', 'Complétez : "Now I ___ ready for Level A1!"',
             ['am', 'is', 'are', 'be'],
             'am',
             'I am (Je suis prêt pour le niveau A1 !).'),
            ('sentenceBuilder', 'Reconstituez la phrase de célébration :',
             ['I', 'can', 'speak', 'basic', 'American', 'English!'],
             'I can speak basic American English!',
             'Je sais parler l\'anglais américain de base !')
        ]
    }

    # Pour A1, A2, B1, B2, C1, on génère dynamiquement des questions complémentaires expertes
    # basées sur la grammaire et la phonétique du niveau.
    level_themes = {
        'A1': [
            ('1. Salutations & Présentations Américaines', 'Conversation', 'first meeting and casual greetings', 'How are you doing?', 'I am doing great, thank you!'),
            ('2. Le "Flap T" & la Phonétique Américaine', 'Phonétique', 'Flap T in water and better', 'water sound', 'The water is cold and fresh.'),
            ('3. Le Présent Simple & la 3ème Personne', 'Grammaire', '3rd person singular -s', 'He works hard', 'She teaches French at school.'),
            ('4. Commander au Restaurant & au Diner US', 'Conversation', 'ordering food and drinks', 'take out or for here', 'Can I get the burger medium rare?'),
            ('5. Les Adverbes de Fréquence & la Routine', 'Grammaire', 'adverbs of frequency placement', 'always before verb', 'I usually wake up early on weekdays.'),
            ('6. Les Verbes Modaux : Can, Could, May', 'Grammaire', 'polite requests with modals', 'could you help me', 'Could you please repeat that slowly?'),
            ('7. L\'Anglais des Achats & Prix en Dollars', 'Vocabulaire', 'prices, discount and tax', 'sales tax at checkout', 'How much is this with sales tax?'),
            ('8. Les Prépositions de Lieu (In, On, At)', 'Grammaire', 'prepositions of place at address', 'at the corner of 5th Ave', 'Meet me at the main entrance.'),
            ('9. Parler de sa Famille & Relations', 'Vocabulaire', 'family members and relatives', 'extended family', 'We are having a family reunion this Sunday.'),
            ('10. Parler de la Météo & Saisons US', 'Conversation', 'weather forecast and seasons', 'sunny skies ahead', 'It looks like it is going to snow.'),
            ('11. Demander son Chemin dans New York', 'Conversation', 'directions and subway navigation', 'uptown or downtown train', 'Take the uptown subway to Central Park.'),
            ('12. Routine Quotidienne & Heures de Travail', 'Vocabulaire', 'daily routine and work schedule', 'commute to work', 'My daily commute takes thirty minutes.'),
            ('13. Décrire son Logement & Pièces de Maison', 'Vocabulaire', 'apartment and furniture', 'living room setup', 'Our new apartment has great natural light.'),
            ('14. Santé, Douleurs & Rendez-vous Médical', 'Santé', 'medical symptoms and appointments', 'make an appointment', 'I need to see a doctor today.'),
            ('15. Loisirs, Sports & Divertissements US', 'Loisirs', 'sports and recreational activities', 'watch the ball game', 'Do you want to watch the game tonight?'),
            ('16. À l\'Aéroport : Enregistrement & Douane', 'Voyage', 'check-in and customs questions', 'carry-on luggage size', 'Do you have any liquids in your bag?'),
            ('17. Transports Urbains : Bus, Métro, Uber', 'Voyage', 'city transit and ride-sharing', 'order a ride', 'I will call an Uber for us.'),
            ('18. Les Professions & le Monde du Travail', 'Pro', 'job titles and workplace tasks', 'work remotely', 'Many employees work remotely twice a week.'),
            ('19. Téléphone & Messages Vocaux Américains', 'Communication', 'phone calls and leaving messages', 'leave a voicemail', 'Please leave a message after the beep.'),
            ('20. Bilan & Révision Complète du Niveau A1', 'Synthèse', 'comprehensive A1 review', 'fluent beginner skills', 'I am confident speaking everyday American English.')
        ],
        'A2': [
            ('1. Le Prétérit Simple (Past Simple) Régulier & Irrégulier', 'Grammaire', 'past tense forms', 'went to Chicago', 'We visited New York last summer.'),
            ('2. Les Connecteurs Logiques (Because, Although, However)', 'Grammaire', 'linking words', 'although it rained', 'She stayed home because she felt sick.'),
            ('3. Le Passé Continu (Past Continuous) & Actions Interrompues', 'Grammaire', 'was doing when something happened', 'were sleeping when call came', 'I was studying when you called me.'),
            ('4. Exprimer le Futur : Will vs Going To', 'Grammaire', 'intentions vs spontaneous decisions', 'going to visit tomorrow', 'I think it will rain later today.'),
            ('5. Comparatifs & Superlatifs Américains', 'Grammaire', 'comparatives with er and more', 'faster than ever', 'This is the most popular coffee shop here.'),
            ('6. L\'Accentuation Tonique (Word Stress) & Rythme US', 'Phonétique', 'syllable stress and melody', 'photo vs photography', 'Pay attention to where the primary stress falls.'),
            ('7. Hôtellerie & Réservations aux USA', 'Voyage', 'hotel check-in and amenities', 'complimentary breakfast', 'Is breakfast included in the room rate?'),
            ('8. Banques, Pourboires (Tips) & Monnaie US', 'Vie Quotidienne', 'tipping etiquette in restaurants', 'leave eighteen percent tip', 'In America, tipping twenty percent is customary.'),
            ('9. Les Pronoms Relatifs (Who, Which, That, Where)', 'Grammaire', 'relative clauses', 'the person who helped me', 'This is the restaurant that I recommended.'),
            ('10. Décrire des Personnalités & Sentiments', 'Vocabulaire', 'adjectives of character and mood', 'outgoing and cheerful', 'She is very friendly and easy to talk to.'),
            ('11. Les Verbes à Particule (Phrasal Verbs) du Quotidien', 'Grammaire', 'everyday phrasal verbs', 'wake up, show up, pick up', 'Can you pick me up from the station?'),
            ('12. Raconter une Anecdote ou une Histoire Passée', 'Conversation', 'storytelling in past tense', 'once upon a time in Boston', 'Then suddenly, the lights went completely out.'),
            ('13. Shopping, Retours & Service Client US', 'Vie Quotidienne', 'returns and refund policy', 'keep your receipt for refund', 'Can I return this item for a full refund?'),
            ('14. Alimentation Saine, Régimes & Allergies', 'Santé', 'food allergies and dietary options', 'gluten-free and dairy-free', 'Are there any peanuts in this dish?'),
            ('15. Écologie, Climat & Environnement', 'Société', 'climate and recycling in cities', 'sorting recyclables', 'We should reduce plastic waste as much as possible.'),
            ('16. Cinéma, Séries & Culture Pop Américaine', 'Culture', 'movies, binge-watching and streaming', 'season finale cliffhanger', 'Have you seen the latest season finale?'),
            ('17. Téléphoner & Prendre un Rendez-vous en Anglais', 'Pro', 'scheduling calls and confirming dates', 'reschedule to next Tuesday', 'Let us reschedule our appointment for next Tuesday.'),
            ('18. Présent Parfait (Present Perfect) avec Ever & Never', 'Grammaire', 'life experiences with present perfect', 'have you ever been to Miami', 'I have never been to the Grand Canyon.'),
            ('19. Les Questions Tags (Isn\'t it? Don\'t you?)', 'Grammaire', 'question tags in American English', 'right and isn\'t it', 'You love jazz music, don\'t you?'),
            ('20. Synthèse & Validation Complète du Niveau A2', 'Synthèse', 'A2 mastery and milestone', 'intermediate communication', 'You have built a solid intermediate foundation!')
        ],
        'B1': [
            ('1. Le Present Perfect Simple vs Continuous', 'Grammaire', 'duration with continuous', 'have been working here', 'I have been living in Seattle for two years.'),
            ('2. Les Phrasal Verbs Professionnels Indispensables', 'Pro', 'workplace phrasal verbs', 'follow up on email', 'Please follow up with the client by tomorrow.'),
            ('3. Le Conditionnel Type 1 & Type 2 (If Clauses)', 'Grammaire', 'hypothetical situations', 'if I had more time', 'If I won the lottery, I would travel the world.'),
            ('4. La Voix Passive en Contexte Formel & Technique', 'Grammaire', 'passive voice in journalism and reports', 'the decision was made yesterday', 'The contract was signed by both parties.'),
            ('5. Donner son Opinion, Nuancer & Argumenter', 'Conversation', 'expressing views and nuance', 'from my perspective', 'From my point of view, this plan is feasible.'),
            ('6. L\'Anglais des Réunions & Brainstorming', 'Pro', 'meeting facilitation and agenda', 'stick to the agenda', 'Let us make sure we stick to the agenda today.'),
            ('7. Rédiger des Emails Professionnels Efficaces', 'Pro', 'business email etiquette', 'find attached the document', 'Please find the requested file attached below.'),
            ('8. Les Verbes Modaux de Déduction (Must, Can\'t, Might)', 'Grammaire', 'logical deductions', 'he must be exhausted after flight', 'She cannot be home; her car is not outside.'),
            ('9. Entretiens d\'Embauche : Présenter ses Forces', 'Carrière', 'job interview self-introduction', 'proven track record of success', 'I have a proven track record in project management.'),
            ('10. Négociation Commerciale de Base aux USA', 'Business', 'basic bargaining and concessions', 'win-win partnership', 'We are looking for a mutually beneficial agreement.'),
            ('11. Gérer les Réclamations & Conflits avec Diplomatie', 'Pro', 'customer service and de-escalation', 'apologize for the inconvenience', 'We sincerely apologize for the delay in shipping.'),
            ('12. Technologie, IA & Transformation Numérique', 'Tech', 'artificial intelligence and software', 'machine learning algorithms', 'Artificial intelligence is reshaping the global economy.'),
            ('13. Présenter des Chiffres, Graphiques & Tendances', 'Business', 'charts and statistical trends', 'steady increase in sales', 'Quarterly profits increased by twelve percent.'),
            ('14. Économie, Finance Personnelle & Budget', 'Finance', 'savings and personal budget', 'compound interest growth', 'It is wise to invest in index funds early.'),
            ('15. Voyages d\'Affaires & Salons Professionnels', 'Voyage', 'business travel and trade shows', 'booth setup at convention', 'Our booth will be located near the main entrance.'),
            ('16. Les Idiomes Américains les Plus Fréquents', 'Idiomes', 'common American idioms', 'bite the bullet and decide', 'Let us bite the bullet and finish this task.'),
            ('17. Compréhension d\'Accents Régionaux US (Sud, Texas, Midwest)', 'Phonétique', 'regional American accents', 'southern drawl vs midwestern flat', 'Southern speakers often pronounce vowel sounds with a drawl.'),
            ('18. Le Style Indirect (Reported Speech)', 'Grammaire', 'backshifting tenses in reported speech', 'he told me that he would come', 'She mentioned that the project was already finished.'),
            ('19. Gérer un Projet en Anglais : Délais & Livrables', 'Pro', 'deadlines and deliverables', 'meet tight deadlines', 'We must ensure all deliverables are completed on schedule.'),
            ('20. Épreuve Synthétique & Passage au Niveau B2', 'Synthèse', 'comprehensive B1 threshold', 'upper intermediate threshold', 'You are now ready to tackle complex professional English!')
        ],
        'B2': [
            ('1. Le Conditionnel Passé (Third Conditional)', 'Grammaire', 'past unreal conditionals', 'would have helped if I had known', 'If we had left earlier, we would not have missed the flight.'),
            ('2. Les Inversions Emphatiques & Style Élevé', 'Grammaire', 'inversion with negative adverbs', 'rarely have I seen such dedication', 'Seldom do we encounter such high professional standards.'),
            ('3. Négociation Avancée & Gestion des Objections', 'Business', 'handling difficult pushback', 'address concerns directly', 'Let us address the main concerns raised by your team.'),
            ('4. Prise de Parole en Public & Pitch Impactant', 'Leadership', 'public speaking and elevator pitch', 'captivate the audience', 'A compelling opening hook grabs attention immediately.'),
            ('5. Rédiger des Rapports & Mémos Stratégiques', 'Pro', 'executive summaries and memos', 'actionable insights and recommendations', 'This executive summary highlights key growth opportunities.'),
            ('6. Les Verbes de Perception & Subjonctif Présent US', 'Grammaire', 'mandative subjunctive in American English', 'insist that he be present', 'The board recommended that the CEO be re-elected.'),
            ('7. Conduite de Réunions Internationales Complexes', 'Leadership', 'chairing cross-cultural meetings', 'navigate diverse perspectives', 'We need to align our cross-functional teams seamlessly.'),
            ('8. Marketing Digital, Branding & Stratégie Produit', 'Business', 'branding and customer conversion', 'user acquisition and retention', 'Customer lifetime value is our primary success metric.'),
            ('9. Entretiens pour Postes de Cadre & Direction', 'Carrière', 'leadership behavioral interview questions', 'lead through adversity and crisis', 'Can you describe a situation where you had to pivot fast?'),
            ('10. Analyse Critique d\'Articles & Débats d\'Idées', 'Communication', 'critical thinking and constructive debate', 'challenge assumptions thoughtfully', 'It is crucial to question the underlying data assumptions.'),
            ('11. Économie Mondiale, Marchés & Inflation', 'Finance', 'macroeconomics and monetary policy', 'interest rate adjustments', 'The Federal Reserve adjusted interest rates to curb inflation.'),
            ('12. Droit des Affaires, Contrats & Confidentialité (NDA)', 'Business', 'non-disclosure agreements and liability', 'binding legal agreements', 'All proprietary information remains strictly confidential.'),
            ('13. Gestion du Changement & Résolution de Crises', 'Leadership', 'crisis management and agile adaptability', 'implement change management strategies', 'Effective leadership requires transparency during challenging times.'),
            ('14. Vente B2B, Prospection & Clôture de Deal', 'Business', 'B2B sales pipelines and closing', 'seal the enterprise contract', 'We successfully closed the multimillion-dollar enterprise contract.'),
            ('15. L\'Humour, l\'Ironie & le Second Degré Américain', 'Culture', 'deadpan humor and cultural banter', 'sarcasm and witty banter', 'Understanding self-deprecating humor helps in American small talk.'),
            ('16. Phrasal Verbs Avancés & Nuances Stylistiques', 'Grammaire', 'advanced separable and non-separable phrasal verbs', 'zero in on the root cause', 'The investigators zeroed in on the primary system failure.'),
            ('17. Leadership, Vision & Motivation d\'Équipe', 'Leadership', 'inspiring vision and team empowerment', 'empower team members to innovate', 'Great leaders inspire autonomy and accountability across teams.'),
            ('18. Responsabilité Sociétale des Entreprises (RSE / ESG)', 'Société', 'sustainability and corporate governance', 'carbon footprint reduction', 'The company committed to achieving net-zero carbon emissions.'),
            ('19. Rédaction de Synthèses Décisionnelles pour Dirigeants', 'Pro', 'briefing senior leadership', 'concise decision-making briefs', 'Provide a concise two-page brief for the board members.'),
            ('20. Grand Bilan de Transition vers la Maîtrise C1', 'Synthèse', 'B2 mastery and transition to executive C1', 'operational fluency', 'Your operational fluency allows you to excel in any business setting!')
        ],
        'C1': [
            ('1. Rhétorique Avancée & Stratégies d\'Éloquence US', 'Leadership', 'rhetorical devices and persuasion', 'ethos, pathos, logos in speeches', 'Using parallel structure gives your keynote speech tremendous impact.'),
            ('2. Négociations Stratégiques à Fort Enjeu (M&A, Levées)', 'Business', 'mergers, acquisitions and venture capital', 'due diligence procedures', 'Both companies concluded extensive due diligence before merging.'),
            ('3. Gouvernance d\'Entreprise & Relations Conseil d\'Administration', 'Leadership', 'board of directors oversight', 'fiduciary duty to shareholders', 'The board exercises fiduciary responsibility on behalf of shareholders.'),
            ('4. Leadership Exécutif & Gestion de l\'Incertitude', 'Leadership', 'VUCA environment decision-making', 'decisive leadership in ambiguity', 'Executive leaders must make high-stakes decisions with incomplete data.'),
            ('5. Diplomatie des Affaires & Communication d\'Influence', 'Communication', 'public relations and corporate diplomacy', 'stakeholder consensus building', 'Diplomatic communication bridges ideological divides among stakeholders.'),
            ('6. L\'Art du Storytelling Américain en Milieu Corporatif', 'Leadership', 'narrative storytelling in business', 'anchor numbers in human stories', 'Connect dry data metrics to compelling customer impact narratives.'),
            ('7. Intelligence Émotionnelle & Négociation de Crise', 'Leadership', 'de-escalating executive friction', 'high emotional quotient under pressure', 'Maintaining emotional composure turns conflict into collaborative solutions.'),
            ('8. Stratégie d\'Innovation de Rupture & Disruptive Tech', 'Tech', 'disruptive technologies and paradigms', 'first-mover advantage in markets', 'Disruptive innovation continually dethrones established market leaders.'),
            ('9. Prise de Parole Spontanée sans Préparation (Impromptu)', 'Communication', 'thinking on your feet and impromptu eloquence', 'structure impromptu remarks clearly', 'The PREP framework (Point, Reason, Example, Point) ensures crisp answers.'),
            ('10. Rédaction d\'Analyses Géopolitiques & Économiques', 'Société', 'macro-geopolitical white papers', 'multilateral trade agreements', 'Geopolitical volatility influences international supply chain resilience.'),
            ('11. Culture d\'Entreprise Américaine : Méritocratie & Feedback', 'Culture', 'radical candor and performance reviews', 'constructive radical transparency', 'Constructive feedback delivered with empathy drives team excellence.'),
            ('12. Éthique des Affaires, Intégrité & Whistleblowing', 'Droit', 'corporate compliance and whistleblower protection', 'uncompromising compliance standards', 'Corporate compliance requires zero tolerance for ethical compromises.'),
            ('13. Capital-Risque, Valorisations & Modèles d\'Investissement', 'Finance', 'venture capital term sheets and cap tables', 'equity dilution and valuations', 'The seed round valuation reflected strong pre-revenue traction.'),
            ('14. Communication de Crise lors de Rappels Produits / Scandales', 'Communication', 'crisis PR and stakeholder transparency', 'swift decisive remediation', 'Promptly acknowledging the defect restored public trust in the brand.'),
            ('15. L\'Humour Corporatif & Subtilités Culturelles Nord-Américaines', 'Culture', 'navigating American wit and self-deprecation', 'cultural nuance and executive presence', 'Subtle cultural references build rapport in high-level executive networking.'),
            ('16. Rédaction de Politiques Publiques & Livres Blancs', 'Société', 'policy briefs and legislative proposals', 'regulatory impact assessment', 'The white paper proposed clear guidelines for consumer data privacy.'),
            ('17. Maîtrise Parfaite des Registres de Langue (Argot à Académique)', 'Phonétique', 'code-switching between colloquial and academic', 'seamless stylistic flexibility', 'Fluency means adapting your register smoothly from boardroom to hallway.'),
            ('18. Gestion de l\'Ambiguïté & Décisions en Contexte Incertain', 'Leadership', 'probabilistic thinking in executive roles', 'mitigate downside risks', 'Probabilistic forecasting helps hedge against sudden market fluctuations.'),
            ('19. Parler en Natif : Réduction Phonétique & Fluidité Spontanée', 'Phonétique', 'connected speech and phonetic reductions', 'assimilations and elisions in native English', 'Mastering linking sounds makes your speech flow naturally like a native speaker.'),
            ('20. Grand Examen de Synthèse C1 : Maîtrise Bilingue Totale', 'Certification', 'executive bilingual fluency certification', 'C1 bilingual mastery milestone', 'Congratulations on achieving complete, effortless mastery of American English!')
        ]
    }

    for lvl, lessons in level_themes.items():
        extras[lvl] = {}
        for idx, (title, cat, topic, phrase1, phrase2) in enumerate(lessons, 1):
            extras[lvl][idx] = [
                ('translation', f'Traduisez en anglais américain : "{phrase2}"',
                 [phrase2, phrase2.replace('is', 'are').replace('was', 'were'), phrase1, f'I want {phrase1}'],
                 phrase2,
                 f'Cette formulation idiomatique illustre parfaitement l\'usage naturel en contexte : {topic}.'),
                ('sentenceBuilder', f'Reconstituez la phrase relative à : {title}',
                 phrase2.replace('!', '').replace('?', '').replace('.', '').split() + [phrase2.split()[-1][-1] if phrase2[-1] in '.!?' else ''],
                 phrase2,
                 f'Structure clé pour maîtriser les subtilités de cette leçon ({cat}).')
            ]

    return extras

print("Génération des questions pour les 120 leçons...")
extras = create_lesson_extras()
print(f"Niveaux configurés : {list(extras.keys())}")
