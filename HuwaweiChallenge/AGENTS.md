# AI Agent Meta-Instructions: Workflow Documentation Tracking

## Objective
You are an AI coding agent assisting in a project that strictly requires documenting all AI-assisted workflows, tools, and generated features. Your secondary, continuous directive is to track your own usage, prompts, and architectural decisions throughout the development lifecycle to generate a compliant AI workflow file upon request.

## Conciseness & Deduplication (Strict Rule)
When tracking your workflow and generating the final documentation, you must heavily compress the information. 
* **No Clutter:** Avoid dumping raw, verbose transcripts of our conversation. 
* **No Repetition:** If an approach or prompt was slightly modified multiple times, summarize the entire cycle into a single concise entry rather than repeating every iteration.
* **Focus on Highlights:** Extract only the core architectural prompts, the final successful tool configurations, and the highest-impact lessons learned.

## Continuous Tracking Requirements
While assisting with development, you must silently keep track of the following information in your context window or a hidden scratchpad:

1. **Tools & Architecture:** Which LLMs, MCP servers, local tools, and Agent Skills you are utilizing to build this project.
2. **Prompts:** The core prompts, system instructions, and user queries that drive major architectural or feature developments.
3. **Iterations & Debugging:** What approaches failed, how they were debugged, and what lessons were learned (summarized).
4. **AI Features:** If you are instructed to build a user-facing AI feature, track the inference flow, data handling, and model selection.

## Security & Privacy Guardrail
**CRITICAL:** Under no circumstances should you ever record, log, or output API keys, personal credentials, proprietary user data, or confidential environment variables in the workflow documentation. Scrub all examples before logging them.

---

## On-Demand Generation: Team Workflow File
When the user asks you to "Generate the AI Workflow file" or "Finalize documentation," write to the single team file **`HuwaweiChallenge/AI_WORKFLOW.md`**. There are **no** per-developer `AI_WORKFLOW_*.md` files.

Every time you write or update this file, you must prepend the entry with the current timestamp.

### Update template

---
## Update: [YYYY-MM-DD HH:MM:SS]
**Developer:** [Git Username]

#### 1. AI Features (Skip if no AI features were built in this session)
* **Model/Service:** [List the specific models or APIs used]
* **Inference Flow:** [Brief description of how inputs travel to the model and outputs are handled]
* **Data Handling & Privacy:** [Explain data security and privacy considerations]
* **Limitations & Validation:** [Note edge cases and how the AI output is validated]

#### 2. AI Development Tools Used
* **Models & Agents:** [e.g., Claude 3.5 Sonnet via Cursor, Devin, ChatGPT]
* **MCP Servers & Skills:** [List any MCP servers or specific Agent Skills used]
* **Configuration:** [Briefly describe the agent setup used]

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** [Brief summary of AI's role in planning]
* **Implementation:** [Concise workflow of generating and building code]
* **Key Prompts:**
  * *Prompt 1:* [Insert sanitized, primary prompt - omit minor follow-ups]
  * *Prompt 2:* [Insert sanitized, primary prompt]
* **Testing & Debugging:** [Brief explanation of how AI was used to diagnose/fix bugs]

#### 4. Review & Validation
* **Human Oversight:** [How the developer validated the AI-generated code]
* **Security Checks:** [How the code was vetted for vulnerabilities]

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** [Condensed summary of failed attempts]
* **Lessons Learned:** [1-2 high-impact takeaways about using AI for this stack]