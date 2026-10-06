for path in ["lib/screens/onboarding_screen.dart", "lib/screens/edit_profile_screen.dart"]:
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    old = """      instituteId: _selectedInstitute!.id,
      instituteName: _selectedInstitute!.name,
      deptCode: _selectedDept!.code,"""
    new = """      instituteId: _selectedInstitute!.id,
      instituteName: _selectedInstitute!.name,
      instituteCode: _selectedInstitute!.code,
      instituteAddress: _selectedInstitute!.address,
      instituteWebsite: _selectedInstitute!.website,
      deptCode: _selectedDept!.code,"""
    if content.count(old) == 1:
        content = content.replace(old, new)
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"✅ {path} updated (onboarding-style var names).")
        continue

    old2 = """      instituteId: _institute!.id,
      instituteName: _institute!.name,
      deptCode: _department!.code,"""
    new2 = """      instituteId: _institute!.id,
      instituteName: _institute!.name,
      instituteCode: _institute!.code,
      instituteAddress: _institute!.address,
      instituteWebsite: _institute!.website,
      deptCode: _department!.code,"""
    if content.count(old2) == 1:
        content = content.replace(old2, new2)
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"✅ {path} updated (edit-profile-style var names).")
        continue

    print(f"⚠️ {path}: neither pattern matched — paste this file's saveProfile() call.")
