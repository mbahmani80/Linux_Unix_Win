import openai
import time

# OpenAI-Client initialisieren
# Ersetze 'your-api-key' durch deinen tatsächlichen API-Schlüssel von OpenAI
#openai.api_key = 'sk-proj-VIimN84al7DbKWktShAbT3BlbkFJiVTcxlNHzx4Hp1bXUZg6'
openai.api_key = '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'

# Funktion zur Abfrage von ChatGPT mit Fehlerbehandlung
def frage_chatgpt(frage):
    try:
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "user", "content": frage}
            ]
        )
        return response.choices[0].message["content"]
    except openai.error.RateLimitError:
        print("Rate limit exceeded. Waiting for 60 seconds before retrying...")
        time.sleep(60)
        return frage_chatgpt(frage)

# Beispiel-Frage
frage = "Was ist die Hauptstadt von Deutschland?"
antwort = frage_chatgpt(frage)

print(f"Frage: {frage}")
print(f"Antwort: {antwort}")
