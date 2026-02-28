from pathlib import Path

from reportlab.lib.pagesizes import letter
from reportlab.lib.utils import simpleSplit
from reportlab.pdfgen import canvas


OUT_PATH = Path("output/pdf/walktracker_app_summary.pdf")


def draw_section_title(c, text, x, y):
    c.setFont("Helvetica-Bold", 11)
    c.drawString(x, y, text)
    return y - 14


def draw_paragraph(c, text, x, y, width, font_size=9.5, leading=12):
    c.setFont("Helvetica", font_size)
    lines = simpleSplit(text, "Helvetica", font_size, width)
    for line in lines:
        c.drawString(x, y, line)
        y -= leading
    return y


def draw_bullets(c, items, x, y, width, font_size=9.5, leading=12):
    c.setFont("Helvetica", font_size)
    bullet_x = x
    text_x = x + 11
    text_width = width - 11
    for item in items:
        wrapped = simpleSplit(item, "Helvetica", font_size, text_width)
        c.drawString(bullet_x, y, "-")
        c.drawString(text_x, y, wrapped[0])
        y -= leading
        for line in wrapped[1:]:
            c.drawString(text_x, y, line)
            y -= leading
    return y


def build_pdf():
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(str(OUT_PATH), pagesize=letter)
    width, height = letter

    margin_x = 40
    y = height - 42
    content_width = width - (2 * margin_x)

    c.setFont("Helvetica-Bold", 16)
    c.drawString(margin_x, y, "WalkTracker - One-Page App Summary")
    y -= 20

    c.setFont("Helvetica", 8.5)
    c.drawString(margin_x, y, "Source basis: README, AndroidManifest, app/build.gradle, and Kotlin source files in this repo.")
    y -= 18

    y = draw_section_title(c, "What It Is", margin_x, y)
    what_it_is = (
        "WalkTracker is a Kotlin/Jetpack Compose Android app for tracking walking sessions with GPS, "
        "distance, and step counts on-device. It uses a foreground location service for live tracking and "
        "stores session history locally with Room and user settings with DataStore."
    )
    y = draw_paragraph(c, what_it_is, margin_x, y, content_width)
    y -= 8

    y = draw_section_title(c, "Who It Is For", margin_x, y)
    who_for = (
        "Primary persona: people who want a simple, privacy-focused walking tracker that works offline. "
        "Formal persona definition document: Not found in repo."
    )
    y = draw_paragraph(c, who_for, margin_x, y, content_width)
    y -= 8

    y = draw_section_title(c, "What It Does", margin_x, y)
    features = [
        "Starts, pauses, resumes, and stops walk sessions from the home screen UI.",
        "Tracks distance via a foreground GPS service with accuracy, age, and movement filtering.",
        "Counts steps using device step sensor when available, with distance-based fallback.",
        "Saves completed sessions (distance, duration, steps) to local Room database history.",
        "Stores preferences in DataStore (units, step length, step-sensor toggle, maps toggle).",
        "Provides a step-length calibration screen based on known distance and step count.",
        "Supports optional Google Maps-based path display; current session/history path loading is currently stubbed to empty in MainActivity.",
    ]
    y = draw_bullets(c, features, margin_x, y, content_width)
    y -= 8

    y = draw_section_title(c, "How It Works (Repo-Evidenced Architecture)", margin_x, y)
    architecture = [
        "UI layer: MainActivity + Compose screens (Home, Settings, Calibration, Map) and navigation.",
        "State layer: MainViewModel coordinates UI state, service binding, Room DAOs, and DataStore preferences.",
        "Tracking layer: LocationService uses FusedLocationProviderClient and exposes distance/path state flows.",
        "Data layer: AppDb (Room) with WalkSession/WalkPath entities and WalkDao/WalkPathDao for persistence.",
        "Data flow: User action -> ViewModel -> LocationService + StepCounter -> UI state updates -> session/path persisted on stop.",
        "External services found in code: Google Play Services Location and optional Google Maps SDK.",
        "Cloud backend/API service implementation: Not found in repo.",
    ]
    y = draw_bullets(c, architecture, margin_x, y, content_width)
    y -= 8

    y = draw_section_title(c, "How To Run (Minimal)", margin_x, y)
    run_steps = [
        "Prereqs: Android Studio, Android SDK 26+, Java 17, and Google Play Services.",
        "Open this project in Android Studio and sync Gradle.",
        "Optional maps: set google_maps_key in app/src/main/res/values/strings.xml.",
        "Run on device/emulator and grant location permissions; CLI build option: ./gradlew assembleDebug.",
    ]
    y = draw_bullets(c, run_steps, margin_x, y, content_width)

    c.showPage()
    c.save()
    return y


if __name__ == "__main__":
    final_y = build_pdf()
    print(f"final_y={final_y:.2f}")
