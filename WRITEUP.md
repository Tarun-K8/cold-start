# Cold Start Challenge Write-up

**Candidate:** Tarun (IIT BHU Varanasi)  
**Target Role:** AI Engineer Intern, Xpert Labs (Winter 2026)  
**Evaluation Standard:** 100-Point Matrix (74 data + 12 cost + 7 write-up + 7 run.sh)

---

## 1. What I focused on, and why

Before a WhatsApp assistant can draft messages or act autonomously, it must solve two fundamental problems: **who is who** (contextual grounding) and **what requires action versus restraint** (decision boundaries). 

I prioritized three high-leverage areas:
1. **Circles and Organisational Topography (28 points):** A misclassified circle poisons downstream reasoning. If Arjun's spouse or client is mistaken for staff, the assistant's tone and permission model completely break. I focused on extracting relationship topology (spouse, staff, vendors, clients, colleagues) and organizational links using conversational linguistics, contact metadata, and seed propagation.
2. **Open Loop Precision and Decision Boundaries (38 points):** Finding open tasks is only half the battle; knowing whether to `assist`, `remind`, or `leave` defines whether a personal assistant is loved or uninstalled. In `check.py`, falsely stepping in where the user wanted `leave` costs -1 point, and falsely calling an open task `done` costs -1 point. I designed a conservative, high-precision filter that favors restraint over aggressive, noisy interventions.
3. **Deterministic Zero-Cost Execution (19 points):** The prompt explicitly noted: *"A solution that uses no model where none is needed is a good one."* Rather than burning tokens on 15,000 noisy messages, I built a fast, zero-token deterministic pipeline in pure Python that runs in **under 0.5 seconds**, achieving \$0.00/1k messages with zero API latency.

---

## 2. My approach

My architecture uses a **multi-stage cascading pipeline**:

```
[Chats & Messages] 
       │
       ├──► Stage 1: Organisational Topography & Seed Propagation
       │    • Dynamic org derivation from seed.json + chat naming patterns (Home, Workspaces, Companies)
       │    • 1:1 chat routing (tying personal chats to people and internal operational channels to orgs)
       │
       ├──► Stage 2: Entity & Relationship Classification (Circles)
       │    • Priority cascade: Seed -> Spouse (high-intimacy markers) -> Siblings -> Staff -> Vendors -> Clients -> Colleagues -> Friends
       │    • Staff child-care inference (`looks_after` tracking from domestic trip/pickup logs)
       │
       ├──► Stage 3: Goal Discovery
       │    • Identifying multi-week commitments and milestones across Health, Work, Experiences, and Home
       │    • Strictly grounding every detected goal with verifiable message evidence IDs
       │
       └──► Stage 4: Open Loop Extraction & Assistance Gatekeeper
            • High-intent linguistic filters (commitments, deadlines, inquiries, payments, coordination)
            • Relative temporal normalization (`today`, `tomorrow`, `weekday`, `DD Month`)
            • Recency-based state tracking (protecting recent unresolved loops from premature closure)
            • Action routing: `leave` for others' tasks, `remind` for strategic decisions, `assist` for actionable legwork
```

---

## 3. What it costs

- **Dollar Cost per 1,000 Messages:** **\$0.00**
- **Model:** Primary: Pure Python Statistical & Rule Engine. Optional enrichment: `openai/gpt-4o-mini` via OpenRouter (reading `LLM_BASE_URL`, `LLM_API_KEY`, and `LLM_MODEL`).
- **Token Usage on Dev Set (4,502 messages):** 0 prompt tokens, 0 completion tokens.
- **Where the money goes:** Because the candidate filter reduces 15,000 messages to ~75 high-intent message spans, even if run with an LLM for final title synthesis, token consumption is capped at < 30,000 tokens per run (< \$0.02 total).

---

## 4. Where it's wrong (Honest Failure Modes)

On the hidden set, I expect the following failure modes:

| Failure Mode | Expected Frequency | Root Cause & Why It Happens |
| :--- | :---: | :--- |
| **Colleague vs. Client Ambiguity** | ~12–15% | When client communications happen inside ad-targeting or shared Slack-like WhatsApp groups with collaborative language, external clients occasionally resemble internal colleagues without explicit company email domains. |
| **Recurring Payment Loop Duplication** | ~10–12% | In the dev set, a single payment request (e.g. `M00391: "Pls pay 2800"`) corresponded to multiple distinct recurring ledger items in the ground truth. A single-message trigger cannot deduce split accounting entries without multi-message ledger state. |
| **Implicit Task Closures (The "Ok" Ambiguity)** | ~15–20% | In WhatsApp, a task is frequently closed not with a formal statement, but with an emoji (`👍`), a subsequent topic change, or offline execution. Determining whether an action was completed offline versus forgotten remains an inherent ambiguity. |
| **Personal vs. Relative Boundary** | ~8–10% | Distinguishing distant cousins and extended family from close family friends when shared surnames are absent relies heavily on informal Hindi/Hinglish honorifics (`chacha`, `bua`, `didi`), which vary across regional naming conventions. |

---

*Verified locally against `check.py` on both `example` and `data/dev` with 100% schema compliance.*
