# -*- coding: utf-8 -*-
import os
import re
import sys

# Import extras dictionary
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__))))
from enrich_all_levels import create_lesson_extras

extras = create_lesson_extras()

curriculum_dir = os.path.abspath('lib/core/data/curriculum')

for lvl in ['A0', 'A1', 'A2', 'B1', 'B2', 'C1']:
    filename = f'curriculum_{lvl.lower()}.dart'
    filepath = os.path.join(curriculum_dir, filename)
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        continue

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pattern to match each Lesson
    # We want to find each lesson and insert Q4 and Q5 at the end of its questions list
    # Lesson id: e.g. id: 'a0_lesson_1' or id: 'a1_lesson_12'
    lesson_pattern = re.compile(
        r"(Lesson\(\s+id:\s*'(?:" + lvl.lower() + r"|a3)_lesson_(\d+)'[^;]*?questions:\s*\[)([\s\S]*?)(\s*\],\s*\),)",
        re.DOTALL
    )

    def replace_lesson(match):
        prefix = match.group(1)
        lesson_num = int(match.group(2))
        existing_questions = match.group(3)
        suffix = match.group(4)

        # Count existing QuizQuestions in this lesson
        q_count = len(re.findall(r'QuizQuestion\(', existing_questions))
        if q_count >= 5:
            # Already has 5 or more questions
            return match.group(0)

        lesson_extra = extras.get(lvl, {}).get(lesson_num, [])
        if not lesson_extra:
            return match.group(0)

        new_questions_str = ""
        for q_idx, q_tuple in enumerate(lesson_extra, start=4):
            q_id = f"{lvl.lower()}_{lesson_num}_{q_idx}"
            
            # Check if this question is a raw string from A0 (already formatted) or a tuple
            if isinstance(q_tuple, str):
                new_questions_str += "\n" + q_tuple.rstrip()
            else:
                q_type, prompt, options, correct, expl = q_tuple
                
                # Format options list
                opts_formatted = ", ".join([f"'{opt.replace(chr(39), chr(92)+chr(39))}'" for opt in options if opt])
                
                if q_type == 'sentenceBuilder':
                    words = [w for w in options if w]
                    words_formatted = ", ".join([f"'{w.replace(chr(39), chr(92)+chr(39))}'" for w in words])
                    new_questions_str += f"""
            QuizQuestion(
              id: '{q_id}',
              type: ExerciseType.sentenceBuilder,
              prompt: '{prompt.replace(chr(39), chr(92)+chr(39))}',
              scrambledWords: [{words_formatted}],
              correctAnswer: '{correct.replace(chr(39), chr(92)+chr(39))}',
              explanationFr: '{expl.replace(chr(39), chr(92)+chr(39))}',
            ),"""
                else:
                    new_questions_str += f"""
            QuizQuestion(
              id: '{q_id}',
              type: ExerciseType.multipleChoice,
              prompt: '{prompt.replace(chr(39), chr(92)+chr(39))}',
              options: [{opts_formatted}],
              correctAnswer: '{correct.replace(chr(39), chr(92)+chr(39))}',
              explanationFr: '{expl.replace(chr(39), chr(92)+chr(39))}',
            ),"""

        return f"{prefix}{existing_questions.rstrip()}{new_questions_str}\n          {suffix.lstrip()}"

    new_content, count = lesson_pattern.subn(replace_lesson, content)
    print(f"[{lvl}] {count} leçons traitées dans {filename}.")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

print("Enrichissement terminé avec succès !")
