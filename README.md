좋습니다. 말씀해주신 대로 **config 레포 README는 안내·관리·사용법 중심**으로 최대한 간결하게 정리해봤습니다.
(branch/PR/배포 전략은 모두 ADR로 분리한다고 가정)

---

# 📖 `config` Repository

V-Ref 전반 공통 규칙·자동화·SSOT(Single Source of Truth) 관리 저장소
모든 레포는 이 저장소 정의를 기준으로 자동화 워크플로를 통해 일관성 유지

---

## 🎯 목적

* 이슈/PR 템플릿 표준화 및 중앙 관리
* 라벨 세트 단일 원천 관리 및 자동 동기화
* 공통 워크플로 제공 (라벨 sync, Org Project 등록 등)
* 레포 성격별 프로파일링(fe/be/infra) 기반 확장 지원

---

## 🛠 사용법

### 1. 이슈 템플릿

* 위치: `.github/ISSUE_TEMPLATE/*.yml`
* 9종 기본 제공: Task, Docs, Feature, Refactor, Test, Chore, Bug, Fix, Idea

### 2. PR 템플릿

* 위치: `.github/PULL_REQUEST_TEMPLATE.md`
* 공통 체크리스트 포함 (AC 충족, 테스트 통과, Docs/ADR 반영 등)

### 3. 라벨 관리

* SSOT: `repo_setup/labels.json`
* 동기화: `repo_setup/sync-labels.sh` 실행 또는 Actions 워크플로 활용

### 4. 워크플로

* 위치: `.github/workflows/`
* 예시:

    * `labels-sync-per-repo.yml` : 라벨 자동 동기화
    * `add-to-project.yml` : Org Project 자동 등록
    * `notion-sync-sample.yml` : Notion DB 연동 샘플

### 5. 프로파일링 (예정)

* `profiles/base` : 모든 레포 공통 규칙
* `profiles/fe|be|infra` : 레포 성격별 규칙
* `mapping/targets.yaml` : 레포 ↔ 프로파일 매핑

---

## 📂 레포 구조

```
config/
├── .github/
│   ├── ISSUE_TEMPLATE/           # 이슈 템플릿
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/                # 공통 워크플로
├── repo_setup/
│   ├── labels.json               # 라벨 SSOT
│   └── sync-labels.sh            # 라벨 동기화 스크립트
├── profiles/                     # (예정) 프로파일별 규칙
│   ├── base/
│   ├── fe/
│   ├── be/
│   └── infra/
├── mapping/
│   └── targets.yaml              # 레포 ↔ 프로파일 매핑
├── .editorconfig
├── .gitignore
├── commitlint.config.js
└── README.md
```

---

## ⏩ 향후 계획

* 프로파일 분리(fe/be/infra) 본격 도입
* Org 단위 Notion/Project/Milestone 오케스트레이션 확장
* CI 재사용 워크플로(Gradle, Vite, Terraform 등) 공통화

---

## 💡 철학

* **SSOT 중심**: 정의(config), 실행(각 레포)
* **자동화 우선**: 수동 관리 최소화
* **점진적 확장**: Day0은 최소 범위 → 단계적 고도화

---

이렇게 정리하면 **config README는 짧고 실행 위주**, 브랜치·PR 정책은 별도 ADR로 관리할 수 있습니다.

👉 이대로 확정해서 push해도 될까요, 아니면 더 줄여서 “설명·목적·사용법·구조” 정도만 남기는 **초간단 버전**을 원하시나요?
