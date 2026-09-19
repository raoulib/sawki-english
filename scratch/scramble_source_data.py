# -*- coding: utf-8 -*-
import re
import glob
import random

def scramble_words_in_curriculum():
    for filepath in glob.glob('lib/core/data/curriculum/curriculum_*.dart'):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        def replacer(match):
            prefix = match.group(1)
            raw_list = match.group(2)
            suffix = match.group(3)

            # Extraire les mots entre guillemets
            words = re.findall(r"'([^']*)'", raw_list)
            if len(words) <= 1:
                return match.group(0)

            # Mélanger les mots
            shuffled = list(words)
            while shuffled == words and len(words) > 1:
                random.shuffle(shuffled)

            formatted_words = ", ".join([f"'{w.replace(chr(39), chr(92)+chr(39))}'" for w in shuffled])
            return f"{prefix}[{formatted_words}]{suffix}"

        new_content, count = re.subn(r"(scrambledWords:\s*)\[(.*?)\](,?(\s*//[^\n]*)?)", replacer, content)
        print(f"Scrambled {count} sentenceBuilder word lists in {filepath}")

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)

if __name__ == '__main__':
    scramble_words_in_curriculum()
