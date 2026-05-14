# Scope Assessment and Product Pressure Test for describe

## Scope Assessment

|Scope|Criteria|Action|
|-|-|-|
|**Lightweight**|Trivial fix, clear requirements, ≤ 1 file|Skip sub-agents. Single-pass problem statement. Skip PPT.|
|**Standard**|Typical feature/fix with some unknowns|Spawn team + visuals. Run PPT.|
|**Deep**|Complex, cross-cutting, security/auth, arch change|Full team + extra research agents. Run PPT.|

**Decision**: 1 file + 1 sentence → Lightweight; Auth/Security/Arch → Deep; else → Standard.

### Spawn Rubric [Ref: composition]
- **Standard**: Domain researcher (`sonnet`) → lead analyst (`opus`) via `/grill-me`.
- **Deep**: Domain researcher + Failure-mode analyst (`sonnet`) → lead analyst (`opus`) via `/grill-me`.

## Product Pressure Test (PPT)

Run between exploration and synthesis (Standard/Deep only). Grill user on:

1. **Right Problem?** → Is this a symptom? Is there a deeper root cause?
2. **Cost of Inaction?** → Who is affected? How badly? Is it worth building?
3. **Leverage?** → Is there a simpler move that captures 80% of value?

*Loop back to exploration if PPT reveals misframing.*
