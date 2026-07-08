# Review Card Spec

## Purpose

The Review Card is the first place where the parent sees what Nabbo understood. This is the **trust moment**.

Nabbo receives messy information, extracts operational meaning, and presents it back in a structured card. The parent verifies quickly, corrects mistakes, assigns ownership, and approves into the household plan.

**If the parent has to rebuild the message by hand, the product has failed.**

---

## Architecture

Review Cards operate on the **unified items collection**:

```
households/{householdId}/items/{id}
```

- A Review Card displays an item with `status: pendingReview`
- Approval changes the status to `confirmed` on the **same document** (no copy)
- Fields are always editable — before and after approval
- Each item links back to its source via `sourceMessageId`

---

## Core Principle

The Review Card separates three things clearly:

1. **What the source says** (original content via sourceMessageId)
2. **What Nabbo extracted** (structured fields on the item)
3. **What Nabbo suggests** (inferred actions in suggestedActions array)

> Parents can tolerate AI uncertainty. They will not tolerate hidden guessing.

---

## Card Structure (6 Zones)

### Zone 1: Source Indicator
Where the item came from: WhatsApp, forwarded email, screenshot, voice note, free text, PDF. Derived from the linked `sourceMessage.inputMethod`.

### Zone 2: Operational Summary
The item's `summary` field — short, plain-English summary of what Nabbo found. Action-focused.

### Zone 3: Extracted Fields
Structured details from the item's fields:
- `title` — action-focused title
- `date` / `endDate` — when it happens
- `location` — where
- `childName` — who it's about
- `ownerName` — who's responsible
- `type` — event / task / deadline
- `notes` — additional context: links, instructions, contacts, form details, what to bring
- `extractedFields` — additional AI-detected key-value pairs

Each field shows confidence from the `confidence` map.

### Zone 4: Uncertainty & Confidence
Fields listed in `uncertainFields` array are clearly marked. Uses the `confidence` map per field.

### Zone 5: Suggested Actions
From the `suggestedActions` array. What Nabbo recommends: approve, assign owner, set reminder, etc.

### Zone 6: Source Message
Expandable original source (fetched via `sourceMessageId`). Shows `originalContent`, `attachmentUrl` if present.

---

## Required Card Elements

- Source type (from linked source message)
- Affected family member (`childName`)
- Item type (`event` / `task` / `deadline`)
- Operational summary (`summary`)
- Key extracted fields
- Confidence / uncertainty markers
- Suggested next steps (`suggestedActions`)
- Primary action button
- Secondary actions
- Source preview + full source access

---

## Field Display by Item Type

| Type | Fields Shown |
|------|-------------|
| **Event** | Title, child, date/time, end time, location, owner, recurrence |
| **Task** | Title, child, due date, owner, priority (from extractedFields) |
| **Deadline** | Title, due date/time, child, owner, urgency |

Additional fields from `extractedFields` map shown as key-value pairs below the main fields.

---

## Confidence Display

Do NOT show numeric confidence to parents (no "87% confidence").

Use simple labels derived from the `confidence` map:

| confidence value | Display Label |
|-----------------|---------------|
| `high` | *Clear* |
| `medium` | *Check this* |
| `low` | *Missing / Unclear* |
| `unknown` | *Missing* |

**Examples:**
- Date: Friday — *Clear*
- Location: Sports Hall — *Check this*
- Owner — *Missing*

---

## Uncertainty Rules

Fields in the `uncertainFields` array are shown with explicit markers:
- "Location may be Main Hall"
- "Child not detected"
- "Time unclear"
- "Owner missing"

Uncertain fields are **editable directly from the card**.

---

## Source Message Rules

- Original source always available via `sourceMessageId` link
- Short preview by default, full source expandable
- For emails: sender, subject, date, relevant excerpt
- For screenshots/images: image preview via `attachmentUrl`
- For voice: transcript (`originalContent`)

**The source message is the trust anchor.**

---

## Primary Actions

Every card has one clear primary action:

| Context | Primary Action | What Happens |
|---------|---------------|--------------|
| Standard extraction | **Approve** | `status` → `confirmed` |
| Low-confidence fields | **Review and approve** | User edits uncertain fields, then approves |
| Missing owner | **Assign owner** | Pick parent/adult, then approve |

---

## Secondary Actions

- **Edit** — inline field editing on the item
- **Delete** — remove item document, mark source as dismissed
- **Assign owner** — choose parent/adult (never a child)
- **View source** — expand original message

Secondary actions sit in a compact menu — do not crowd the card.

---

## Action Behaviors

### Approve
Changes `status` from `pendingReview` to `confirmed`. Item immediately appears as active in Feed. Confirmation shown briefly.

### Edit
Fast, inline editing directly on the item document. Editable fields: title, child, date, time, location, owner, type, summary, any field in `extractedFields`.

**If editing feels like data entry, Nabbo loses.**

### Delete
Removes the item document from `items/`. Updates linked source message `processingStatus` to `dismissed` if all items from that source are deleted. Recoverable briefly via undo.

### Assign Owner
Choose from household members with parent/adult role only. Never assign to children. Sets `ownerId` and `ownerName` on the item.

---

## Review Queue (Review Tab)

Shows all items with `status: pendingReview`, newest first.

Priority indicators:
- Due today / tomorrow (date is soon)
- Deadline type items
- Items with many uncertain fields

**Do not encourage bulk approval** — it creates trust risk.

---

## Review Card Quality Bar

A good Review Card passes five tests:

1. ✅ Parent understands the item in **5 seconds**
2. ✅ Parent can verify the source **quickly**
3. ✅ Uncertainty is **visible**
4. ✅ Next action is **obvious**
5. ✅ Approval does not require **manual reconstruction**

---

## Examples

### School Trip Extraction

```
Source: Forwarded school email
Child: Adam — Clear

Summary: Adam has a school trip to the science museum on Friday.
He needs packed lunch, water bottle, and raincoat.

Type: Event
Date: Friday — Clear
Location: Science museum — Clear
Owner: Missing

Extracted fields:
  Required items: packed lunch, water bottle, raincoat — Clear
  
Suggested: Approve event, assign owner, create task for packing.

[Approve]  [Edit] [Assign Owner] [Delete]
```

### Free Text Capture

```
Source: Typed note
Child: Yara — Clear

Summary: Yara needs €5 for school tomorrow.

Type: Task
Date: tomorrow — Clear
Owner: Missing

Extracted fields:
  Amount: €5 — Clear

Suggested: Approve, assign owner.

[Approve]  [Assign Owner] [Edit] [Delete]
```

---

## Design Rules

- Clean, compact, decisive
- No technical AI details shown to user
- No raw JSON or confidence numbers
- Don't hide source material
- Don't bury uncertain fields
- Don't make editing feel like form filling
- Don't treat all items the same — type and urgency matter
- Don't allow items to enter the plan without review (no auto-approve)
- Items remain editable after approval (from Feed detail screen)
