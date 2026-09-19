# -*- coding: utf-8 -*-
import re
import glob

def fix_all_sentence_builders():
    for filepath in glob.glob('lib/core/data/curriculum/curriculum_*.dart'):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Find every QuizQuestion block
        # Match QuizQuestion( ... type: ExerciseType.sentenceBuilder ... correctAnswer: '...' ... )
        def fix_question(match):
            q_block = match.group(0)
            
            # Extract correctAnswer
            m_correct = re.search(r"correctAnswer:\s*'((?:[^'\\]|\\.)*)'", q_block)
            if not m_correct:
                m_correct = re.search(r'correctAnswer:\s*"((?:[^"\\]|\\.)*)"', q_block)
            
            if not m_correct:
                return q_block
            
            correct_str = m_correct.group(1)
            # Unescape \' to ' for splitting, then re-escape
            clean_correct = correct_str.replace(r"\'", "'").replace(r'\"', '"')
            words = [w for w in clean_correct.split() if w]
            
            if not words:
                return q_block
            
            # Format words list with proper Dart escaping
            # Each word inside '...' with ' escaped as \'
            words_formatted = ", ".join([f"'{w.replace(chr(39), chr(92)+chr(39))}'" for w in words])
            
            # Replace scrambledWords in this block
            new_block = re.sub(
                r"scrambledWords:\s*\[.*?\]",
                f"scrambledWords: [{words_formatted}]",
                q_block,
                flags=re.DOTALL
            )
            return new_block

        # Match each QuizQuestion( ... )
        new_content = re.sub(
            r"QuizQuestion\(\s*id:\s*'[^']+',\s*type:\s*ExerciseType\.sentenceBuilder,[\s\S]*?\),",
            fix_question,
            content
        )

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed sentence builders in {filepath}")

if __name__ == '__main__':
    fix_all_sentence_builders()
