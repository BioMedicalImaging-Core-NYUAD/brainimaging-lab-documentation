Protocol for TNT
================

---

### 🔢 **2-Back Math Task – Simple Description**

This is a computerized **2-back working memory task** using simple **mental addition**.

* On each trial, the screen shows a math problem: **A + B**, where both A and B are numbers between 0 and 10.
* The participant must mentally solve the addition.
* They must press the **right arrow key** **only** if the current answer is **equal to the answer shown two trials ago** (that is, it "matches" the one 2 steps back).
* If it matches and they respond, the program shows **"Correct!"** in green.
* If they respond when it’s not a match, it shows **"Incorrect!"** in red.
* If they **miss a match** (i.e., it was a 2-back match but they didn't respond), the screen shows **"Missed!"** in orange.
* If it's not a match and they don't press, nothing happens (as expected).

---

### ⏱️ Task Timing & Structure

* Each trial displays a math problem for **2.5 seconds**.
* Then there's a **0.5 second pause** before the next one.
* Every **12 trials**, there's a **24-second break**, during which "00 + 00" is shown on the screen.
* A **progress bar** appears at the top of the screen, shrinking as time runs out for each trial.

---

### 📊 At the end:

* It calculates your **accuracy only for the matching trials**, based on how many you caught.
* It saves all the responses, timings, and accuracy to a `.mat` file on your computer.

---




- Requires Vpixx responsepixx button box, only one button is needed
