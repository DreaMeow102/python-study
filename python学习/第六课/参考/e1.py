# @预期
# [42] isdigit=True isalpha=False isspace=False isalnum=True
# [+7] isdigit=False isalpha=False isspace=False isalnum=False
# [2.5] isdigit=False isalpha=False isspace=False isalnum=False
# [４５] isdigit=True isalpha=False isspace=False isalnum=True
# [ 9 ] isdigit=False isalpha=False isspace=False isalnum=False
# [²] isdigit=True isalpha=False isspace=False isalnum=True
# 42 9
# @结束
tests = ["42", "+7", "2.5", "４５", " 9 ", "²"]
for t in tests:
    print(f"[{t}] isdigit={t.isdigit()} isalpha={t.isalpha()} isspace={t.isspace()} isalnum={t.isalnum()}")
print(int("42"), int(" 9 "))