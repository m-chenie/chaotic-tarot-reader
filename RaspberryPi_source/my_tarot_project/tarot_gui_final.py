#!/usr/bin/env python3
import tkinter as tk
from tkinter.scrolledtext import ScrolledText
from PIL import Image, ImageTk
import glob, os, random, serial
import tkinter.font as tkFont
import time

# --- Configuration ---
test_mode    = False
CARDS_DIR    = "/home/DomPie/Documents/my_tarot_project/cards"
SERIAL_PORT  = "/dev/serial0"   # Pi’s GPIO UART
BAUDRATE     = 9600
READ_TIMEOUT = 2.0              # seconds per read

# --- Tarot Data ---
major_arcana = ["The Fool", "The Magician", "The High Priestess", "...", "The World"]
suits = ["Wands", "Cups", "Swords", "Pentacles"]
ranks = ["Ace", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Page", "Knight", "Queen", "King"]
minor_arcana = [f"{r} of {s}" for s in suits for r in ranks]
full_deck = major_arcana + minor_arcana
DECK_SIZE = len(full_deck)

card_keywords = {
    # Major Arcana
    "The Fool": ["Beginnings", "Spontaneity", "Faith", "Innocence", "Potential", "Risk", "Leap of Faith"],
    "The Magician": ["Manifestation", "Skill", "Power", "Action", "Resourcefulness", "Concentration", "Willpower"],
    "The High Priestess": ["Intuition", "Secrets", "Subconscious", "Mystery", "Inner Voice", "Stillness", "Hidden Knowledge"],
    "The Empress": ["Nurturing", "Fertility", "Abundance", "Creativity", "Nature", "Comfort", "Motherhood"],
    "The Emperor": ["Structure", "Authority", "Control", "Stability", "Leadership", "Rules", "Fatherhood"],
    "The Hierophant": ["Tradition", "Convention", "Institutions", "Guidance", "Belief Systems", "Education", "Spiritual Wisdom"],
    "The Lovers": ["Choice", "Relationships", "Harmony", "Union", "Values", "Alignment", "Duality"],
    "The Chariot": ["Willpower", "Determination", "Control", "Momentum", "Victory", "Ambition", "Direction"],
    "Strength": ["Inner Strength", "Courage", "Patience", "Compassion", "Influence", "Self-Control", "Taming"],
    "The Hermit": ["Introspection", "Solitude", "Guidance (Inner)", "Wisdom", "Searching", "Soul-searching", "Reflection"],
    "Wheel of Fortune": ["Cycles", "Change", "Fate", "Luck", "Turning Point", "Movement", "Destiny"],
    "Justice": ["Fairness", "Truth", "Cause and Effect", "Balance", "Law", "Accountability", "Clarity"],
    "The Hanged Man": ["Suspension", "Surrender", "New Perspective", "Letting Go", "Sacrifice (for insight)", "Waiting"],
    "Death": ["Endings", "Transformation", "Transition", "Letting Go", "Change (Inevitable)", "Metamorphosis"],
    "Temperance": ["Balance", "Moderation", "Patience", "Integration", "Harmony", "Blending", "Purpose"],
    "The Devil": ["Bondage", "Materialism", "Addiction", "Restriction", "Shadow Self", "Temptation", "Obsession"],
    "The Tower": ["Sudden Change", "Upheaval", "Revelation", "Destruction (for Rebirth)", "Awakening", "Crisis"],
    "The Star": ["Hope", "Inspiration", "Healing", "Serenity", "Guidance", "Optimism", "Renewal"],
    "The Moon": ["Illusion", "Fear", "Anxiety", "Subconscious", "Intuition (Deep)", "Uncertainty", "Dreams"],
    "The Sun": ["Joy", "Success", "Vitality", "Clarity", "Warmth", "Optimism", "Enlightenment"],
    "Judgement": ["Reckoning", "Awakening", "Decision", "Rebirth", "Calling", "Absolution", "Evaluation"],
    "The World": ["Completion", "Integration", "Accomplishment", "Travel", "Wholeness", "Success", "Fulfillment"],

    # Pentacles (Material World, Resources, Practicality, Body)
    "Ace of Pentacles": ["New Opportunity (Material)", "Prosperity", "Manifestation (Practical)", "Stability", "Resource", "Foundation"],
    "Two of Pentacles": ["Balance", "Adaptability", "Juggling", "Prioritization", "Flexibility", "Managing Resources"],
    "Three of Pentacles": ["Teamwork", "Collaboration", "Skill", "Craftsmanship", "Learning", "Initial Success"],
    "Four of Pentacles": ["Control", "Security", "Conservation", "Possessiveness", "Stability (Rigid)", "Saving"],
    "Five of Pentacles": ["Hardship", "Loss (Material)", "Poverty", "Isolation", "Worry", "Insecurity", "Need"],
    "Six of Pentacles": ["Generosity", "Charity", "Giving/Receiving", "Balance (Resources)", "Sharing", "Debt/Payment"],
    "Seven of Pentacles": ["Patience", "Investment", "Waiting (for results)", "Assessment", "Perseverance", "Long-term View"],
    "Eight of Pentacles": ["Skill Development", "Diligence", "Mastery", "Craftsmanship", "Repetition", "Focus on Detail"],
    "Nine of Pentacles": ["Abundance", "Self-Sufficiency", "Luxury", "Independence (Material)", "Gratitude", "Comfort"],
    "Ten of Pentacles": ["Legacy", "Wealth", "Family", "Long-term Stability", "Inheritance", "Completion (Material)", "Foundation (Solid)"],
    "Page of Pentacles": ["Manifestation (Early)", "Learning", "Practicality", "New Opportunity (Study/Work)", "Diligence", "Foundation"],
    "Knight of Pentacles": ["Hard Work", "Routine", "Responsibility", "Diligence", "Reliability", "Methodical Approach"],
    "Queen of Pentacles": ["Nurturing", "Practicality", "Comfort", "Security", "Groundedness", "Resourcefulness"],
    "King of Pentacles": ["Abundance", "Security", "Business Acumen", "Leadership (Practical)", "Prosperity", "Reliability", "Provider"],
    
    # Wands (Action, Energy, Passion, Creativity)
    "Ace of Wands": ["New Spark", "Inspiration", "Potential (Action)", "Growth", "Creativity", "Energy Burst"],
    "Two of Wands": ["Planning", "Future Vision", "Decision (Path)", "Potential (Exploration)", "Partnership (Initial)"],
    "Three of Wands": ["Expansion", "Foresight", "Waiting (for results)", "Progress", "Overseas", "Teamwork"],
    "Four of Wands": ["Celebration", "Harmony", "Homecoming", "Stability (Initial)", "Community", "Joy"],
    "Five of Wands": ["Competition", "Conflict (Minor)", "Disagreement", "Strife", "Challenge", "Rivalry"],
    "Six of Wands": ["Victory", "Recognition", "Success", "Acclaim", "Progress", "Self-Confidence"],
    "Seven of Wands": ["Defense", "Challenge", "Perseverance", "Maintaining Control", "Standing Ground", "Courage"],
    "Eight of Wands": ["Speed", "Action", "Movement", "Communication (Swift)", "Progress (Rapid)", "News"],
    "Nine of Wands": ["Resilience", "Persistence", "Last Stand", "Boundaries", "Defensiveness", "Fatigue but Standing"],
    "Ten of Wands": ["Burden", "Responsibility", "Overload", "Struggle", "Completion (Hard Won)", "Stress"],
    "Page of Wands": ["Enthusiasm", "Exploration", "Discovery", "Free Spirit", "Creative Spark", "New Idea"],
    "Knight of Wands": ["Action", "Adventure", "Impulsiveness", "Passion", "Energy", "Moving Fast"],
    "Queen of Wands": ["Confidence", "Independence", "Warmth", "Courage", "Determination", "Social Butterfly"],
    "King of Wands": ["Leadership", "Vision", "Entrepreneurship", "Charisma", "Boldness", "Taking Control"],

    # Cups (Emotions, Relationships, Intuition, Creativity)
    "Ace of Cups": ["New Emotions", "Love", "Intuition", "Beginnings (Emotional)", "Joy", "Compassion"],
    "Two of Cups": ["Partnership", "Union", "Mutual Attraction", "Harmony (Relational)", "Connection", "Shared Feelings"],
    "Three of Cups": ["Celebration", "Friendship", "Community", "Collaboration", "Joy (Shared)", "Gathering"],
    "Four of Cups": ["Apathy", "Contemplation", "Missed Opportunity", "Re-evaluation", "Discontent", "Meditation"],
    "Five of Cups": ["Loss", "Regret", "Disappointment", "Sadness", "Focus on Negative", "Grief"],
    "Six of Cups": ["Nostalgia", "Childhood", "Memories", "Innocence", "Giving/Receiving", "Past Influences"],
    "Seven of Cups": ["Choices", "Illusion", "Fantasy", "Options", "Wishful Thinking", "Temptation (Emotional)"],
    "Eight of Cups": ["Moving On", "Abandonment (of situation)", "Seeking Deeper Meaning", "Withdrawal", "Journey (Emotional)"],
    "Nine of Cups": ["Wishes Fulfilled", "Contentment", "Satisfaction", "Emotional Stability", "Comfort", "Gratitude"],
    "Ten of Cups": ["Emotional Fulfillment", "Family", "Happiness", "Harmony (Home)", "Contentment", "Joy (Lasting)"],
    "Page of Cups": ["Creative Opportunity", "Intuitive Message", "Curiosity", "Sensitivity", "Dreaminess", "Inner Child"],
    "Knight of Cups": ["Romance", "Charm", "Imagination", "Following the Heart", "Idealism", "Offer (Emotional)"],
    "Queen of Cups": ["Emotional Security", "Compassion", "Intuition", "Nurturing", "Empathy", "Calmness"],
    "King of Cups": ["Emotional Balance", "Control (Emotional)", "Compassion", "Diplomacy", "Wisdom (Emotional)", "Generosity"],

    # Swords (Intellect, Thoughts, Conflict, Truth)
    "Ace of Swords": ["Mental Clarity", "Breakthrough", "Truth", "New Idea", "Focus", "Sharpness", "Justice"],
    "Two of Swords": ["Stalemate", "Indecision", "Blocked Emotions", "Truce", "Avoidance", "Difficult Choice"],
    "Three of Swords": ["Heartbreak", "Sorrow", "Painful Truth", "Grief", "Separation", "Rejection"],
    "Four of Swords": ["Rest", "Recuperation", "Contemplation", "Meditation", "Stillness", "Mental Break"],
    "Five of Swords": ["Conflict (Costly)", "Defeat", "Loss", "Hollow Victory", "Bullying", "Self-Interest"],
    "Six of Swords": ["Transition", "Moving On (Mentally)", "Rite of Passage", "Leaving Trouble Behind", "Journey (Mental)"],
    "Seven of Swords": ["Deception", "Strategy", "Sneakiness", "Theft", "Acting Alone", "Hidden Motives"],
    "Eight of Swords": ["Restriction", "Limiting Beliefs", "Feeling Trapped", "Victim Mentality", "Self-Imposed Prison"],
    "Nine of Swords": ["Anxiety", "Worry", "Fear", "Nightmares", "Despair", "Mental Anguish"],
    "Ten of Swords": ["Rock Bottom", "Endings (Painful)", "Failure", "Exhaustion", "Betrayal", "Finality"],
    "Page of Swords": ["Curiosity", "New Ideas", "Truth Seeking", "Mental Energy", "Restlessness", "Communication"],
    "Knight of Swords": ["Action (Hasty)", "Ambition", "Assertiveness", "Charging Ahead", "Focus (Intense)", "Directness"],
    "Queen of Swords": ["Independence", "Sharp Wit", "Direct Communication", "Boundaries", "Clarity", "Unbiased Judgement"],
    "King of Swords": ["Mental Clarity", "Authority (Intellectual)", "Truth", "Logic", "Ethics", "Decision Maker"]

    
}

def get_keywords(card_name):
    kws = card_keywords.get(card_name, [])
    placeholders = ["an unseen current", "a veiled influence", "a subtle vibration"]
    return (kws + placeholders)[:3]

def interpret_mystical_narrative(c1, c2, c3):
    k1, k2, k3 = get_keywords(c1), get_keywords(c2), get_keywords(c3)
    txt  = "~*~ The cosmic veil parts, revealing whispers of your path... ~*~\n\n"
    txt += f"Past:    {c1}\n  echoes of '{k1[0]}', '{k1[1]}', '{k1[2]}'\n\n"
    txt += f"Present: {c2}\n  currents of '{k2[0]}', '{k2[1]}', '{k2[2]}'\n\n"
    txt += f"Future:  {c3}\n  portents of '{k3[0]}', '{k3[1]}', '{k3[2]}'\n\n"
    txt += "~*~ The threads are shown, but the weaving is yours. ~*~"
    return txt

def get_indices_from_uart(port, baud, timeout):
    """
    Reads bytes from UART, ignoring 0x00 and 0xFF.
    Returns 3 indices in [0, DECK_SIZE).
    """
    try:
        ser = serial.Serial(port, baud, timeout=timeout)
        valid_bytes = []
        attempts = 0
        while len(valid_bytes) < 3:
            raw = ser.read(1)
            if not raw:
                break
            byte = raw[0]
            if byte not in (0x00, 0xFF):
                valid_bytes.append(byte)
            attempts += 1

        leftover = ser.in_waiting
        ser.close()

        if len(valid_bytes) < 3:
            print(f"[UART WARNING] Only got {len(valid_bytes)} valid byte(s), defaulting to [0, 1, 2]")
            return [0, 1, 2]

        idxs = [b % DECK_SIZE for b in valid_bytes[:3]]
        return idxs

    except Exception as e:
        print(f"[UART ERROR] {e}")
        return [0, 1, 2]

# --- UI Setup ---
root = tk.Tk()
root.title("Tarot Oracle")
root.geometry("320x240")
root.bind("<Escape>", lambda e: root.destroy())

def go_fullscreen():
    root.attributes("-fullscreen", True)
root.after(1000, go_fullscreen)

# Background
bg = Image.open("/home/DomPie/Documents/my_tarot_project/backgrounds/stars.jpg") \
         .resize((root.winfo_screenwidth(), root.winfo_screenheight()), Image.Resampling.LANCZOS)
bg_photo = ImageTk.PhotoImage(bg)
tk.Label(root, image=bg_photo).place(x=0, y=0, relwidth=1, relheight=1)

# Containers
main_frame = tk.Frame(root, bg="#1e1e2e")
main_frame.place(relx=0.5, rely=0.5, anchor="center")
card_frames = tk.Frame(main_frame, bg="#1e1e2e", padx=5, pady=5)
narrative_frame = tk.Frame(main_frame, bg="#1e1e2e")
card_frames.pack(side="left")
narrative_frame.pack(side="right", padx=(10, 0))

# Load card images
paths = sorted(glob.glob(os.path.join(CARDS_DIR, "*.png")),
               key=lambda p: int(os.path.splitext(os.path.basename(p))[0]))
photos, labels = [None] * 3, []
mystic_font = tkFont.Font(family="FreeSerif", size=12, weight="bold")
for _ in range(3):
    lbl = tk.Label(card_frames, bg="#1e1e2e")
    lbl.pack(side="left", padx=5)
    labels.append(lbl)

message_container = None
message_box = None

def draw_reading(idxs=None):
    global message_container, message_box
    if message_container:
        message_container.destroy()

    if idxs is None:
        if test_mode:
            sets = [[0, 1, 2], [75, 76, 77], [33, 44, 55]]
            draw_reading.counter = (getattr(draw_reading, "counter", -1) + 1) % len(sets)
            idxs = sets[draw_reading.counter]
        else:
            try:
                with serial.Serial(SERIAL_PORT, BAUDRATE, timeout=0.5) as ser:
                    ser.reset_input_buffer()
            except Exception as e:
                print(f"[UART FLUSH ERROR] {e}")
            idxs = get_indices_from_uart(SERIAL_PORT, BAUDRATE, READ_TIMEOUT)

    cw, ch = 160, 240
    for i, idx in enumerate(idxs):
        img = Image.open(paths[idx]).resize((cw, ch), Image.Resampling.LANCZOS)
        photos[i] = ImageTk.PhotoImage(img)
        labels[i].config(image=photos[i])

    c1, c2, c3 = (full_deck[i] for i in idxs)
    narration = interpret_mystical_narrative(c1, c2, c3)

    message_container = tk.Frame(narrative_frame, bg="#1e1e2e")
    message_container.pack()
    message_box = ScrolledText(
        message_container, height=10, width=30, wrap="word",
        bg="#1e1e2e", fg="#f0e6d2", font=("Georgia", 10, "italic"),
        relief="flat", bd=0
    )
    message_box.insert(tk.END, narration)
    message_box.config(state=tk.DISABLED)
    message_box.pack(padx=10, pady=5)

btn = tk.Button(root, text="Draw Your Fate", command=lambda: draw_reading(),
                font=mystic_font, bg="#8e44ad", fg="white")
btn.place(relx=0.5, rely=1.0, anchor="s", y=-10)

# Start idle in test mode or blank reading
draw_reading()
root.mainloop()
