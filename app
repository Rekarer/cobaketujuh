<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aplikasi Pencatat Murid Terlambat (Suara & Dropdown)</title>
    <!-- Load Tailwind CSS dari CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        /* Pengaturan font dan latar belakang global */
        body {
            font-family: 'Inter', sans-serif;
            background-color: #f0fdf4; /* Latar belakang hijau pucat untuk tema absensi */
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        /* Style untuk efek tombol hover/active */
        button {
            transition: all 0.15s ease-in-out;
            transform: translateZ(0);
        }
    </style>
</head>
<body class="p-4">

    <div class="w-full max-w-lg bg-white shadow-2xl rounded-3xl p-6 md:p-8 space-y-6 border border-green-200 transform transition-all duration-300 hover:shadow-green-300/50">
        <h1 class="text-3xl font-extrabold text-green-700 text-center">Pencatat Keterlambatan Sekolah</h1>
        <p class="text-center text-sm text-gray-500">Ucapkan nama, pilih kelas, dan data akan dicatat real-time via Telegram.</p>

        <!-- Status & Output Section -->
        <div class="bg-green-50 border-2 border-green-300/50 rounded-xl p-4 space-y-3 shadow-inner">
            <div id="status" class="text-lg font-bold text-green-700">Status: Belum dimulai</div>
            <div id="message" class="text-sm font-medium min-h-[1.25rem]"></div>
            
            <div class="bg-white p-4 rounded-lg border border-gray-200 min-h-[4rem] whitespace-pre-wrap shadow-sm">
                <p class="text-gray-400 text-xs mb-1 font-semibold">Nama Murid (Hasil Ucapan):</p>
                <p id="output" class="text-gray-800 text-base font-medium">Tekan tombol 'Mulai' untuk menyebutkan nama.</p>
            </div>
        </div>

        <!-- Class Dropdown -->
        <div>
            <label for="classDropdown" class="block text-sm font-medium text-gray-700 mb-2">Pilih Kelas Murid:</label>
            <select id="classDropdown" class="w-full p-3 border border-gray-300 rounded-xl focus:ring-green-500 focus:border-green-500 shadow-sm text-gray-700">
                <option value="" disabled selected>--- Pilih Kelas ---</option>
                <option value="XI-A">XI-A</option>
                <option value="XI-B">XI-B</option>
                <option value="XI-C">XI-C</option>
                <option value="XI-D">XI-D</option>
                <option value="XI-E">XI-E</option>
                <option value="XI-F">XI-F</option>
                <option value="XI-G">XI-G</option>
                <option value="XI-H">XI-H</option>
            </select>
        </div>
        
        <!-- Control Buttons -->
        <div class="flex flex-col sm:flex-row space-y-4 sm:space-y-0 sm:space-x-4">
            <button id="startBtn" class="flex-1 px-6 py-3 bg-green-600 text-white font-extrabold rounded-xl shadow-lg shadow-green-400/50 hover:bg-green-700 disabled:opacity-50 disabled:shadow-none">
                1. Ucapkan Nama Murid
            </button>
            <button id="stopBtn" disabled class="flex-1 px-6 py-3 bg-red-600 text-white font-extrabold rounded-xl shadow-lg shadow-red-400/50 hover:bg-red-700 disabled:opacity-50 disabled:shadow-none">
                Stop
            </button>
        </div>
        <button id="sendBtn" disabled class="w-full px-6 py-3 bg-blue-600 text-white font-extrabold rounded-xl shadow-xl shadow-blue-400/50 hover:bg-blue-700 disabled:opacity-50 disabled:shadow-none">
            2. Klik Disini Untuk Kirim
        </button>

    </div>

    <script type="text/javascript">
        // Global Constants and Setup
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;

        const startBtn = document.getElementById("startBtn");
        const stopBtn = document.getElementById("stopBtn");
        const sendBtn = document.getElementById("sendBtn");
        const statusEl = document.getElementById("status");
        const outputEl = document.getElementById("output");
        const messageEl = document.getElementById("message");
        const classDropdown = document.getElementById("classDropdown");

        // ***************************************************************
        // GANTI URL ini dengan URL Webhook Pabbly Connect Anda yang sebenarnya
        const PABBLY_WEBHOOK_URL = 'https://connect.pabbly.com/workflow/sendwebhookdata/IjU3NjYwNTY0MDYzZjA0M2Q1MjY4NTUzMDUxMzAi_pc'; 
        // ***************************************************************

        // Telegram Constants (dari kode awal user - tetap dipertahankan)
        const TELEGRAM_TOKEN = "8094088254:AAHhx11hS3pBMyWrqjxKrd3oeRbA3joeB5c";
        const TELEGRAM_CHAT_ID = "1389280044";

        let rec;
        let lastTranscript = "";

        // Fungsi untuk menampilkan pesan temporer di UI (pengganti alert())
        function showMessage(text, isError = true) {
            messageEl.textContent = text;
            messageEl.classList.remove('text-red-600', 'text-green-600', 'text-blue-600');
            messageEl.classList.add(isError ? 'text-red-600' : (isError === false ? 'text-green-600' : 'text-blue-600'));
            setTimeout(() => {
                messageEl.textContent = "";
            }, 5000);
        }

        if (!SpeechRecognition) {
            outputEl.textContent = "Browser Anda tidak mendukung Web Speech API.";
            showMessage("Browser Anda tidak mendukung Web Speech API.", true);
        } else {
            rec = new SpeechRecognition();
            rec.lang = "id-ID";
            rec.interimResults = false;
            rec.continuous = false; // Diubah ke false, karena kita hanya butuh satu nama per sesi

            rec.onstart = () => {
                statusEl.textContent = "Status: 🟢 Mendengarkan Nama Murid...";
                startBtn.disabled = true;
                stopBtn.disabled = false;
                sendBtn.disabled = true;
                messageEl.textContent = "";
            };

            rec.onend = () => {
                statusEl.textContent = "Status: 🟡 Idle. Perekaman selesai.";
                startBtn.disabled = false;
                stopBtn.disabled = true;
            };

            rec.onerror = (event) => {
                console.error("Speech Recognition Error:", event.error);
                statusEl.textContent = "Status: 🔴 Error (" + event.error + ")";
                showMessage("Error pengenalan suara: " + event.error, true);
            }

            rec.onresult = (event) => {
                const result = event.results[event.results.length - 1];
                if (result.isFinal) {
                    const text = result[0].transcript;
                    lastTranscript = text.trim().toUpperCase(); // Simpan dan ubah ke huruf besar
                    outputEl.textContent = lastTranscript;
                    sendBtn.disabled = false; // aktifkan tombol kirim
                    statusEl.textContent = "Status: ✅ Nama didapat. Pilih Kelas dan Kirim.";
                }
            };

            startBtn.onclick = () => {
                try { 
                    rec.start(); 
                    lastTranscript = "";
                    outputEl.textContent = "Sedang mendengarkan...";
                    sendBtn.disabled = true;
                    // classDropdown.value = ""; // Opsi: Reset kelas saat mulai
                } catch (e) { 
                    console.error("Gagal memulai perekaman:", e);
                    showMessage("Gagal memulai perekaman. Mungkin sudah berjalan?", true);
                }
            };

            stopBtn.onclick = () => rec.stop();
        }

        // === FUNGSI KIRIM ===

        // Mengambil waktu dan tanggal saat ini
        function getCurrentDateTime() {
            const now = new Date();
            const dateOptions = { year: 'numeric', month: '2-digit', day: '2-digit' };
            const timeOptions = { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false };
            
            return {
                date: now.toLocaleDateString('id-ID', dateOptions), // Contoh: 25/11/2025
                time: now.toLocaleTimeString('id-ID', timeOptions)  // Contoh: 06:11:45
            };
        }

        // FUNGSI UTAMA: Mengirim ke Webhook Pabbly
        sendBtn.onclick = () => {
            const selectedClass = classDropdown.value;
            
            if (!lastTranscript) {
                return showMessage("Belum ada Nama Murid yang diucapkan!", true);
            }
            if (!selectedClass) {
                return showMessage("Harap pilih Kelas Murid terlebih dahulu!", true);
            }
            
            // Nonaktifkan tombol kirim sementara proses sedang berjalan
            sendBtn.disabled = true;
            statusEl.textContent = "Status: 📤 Mengirim data ke Pabbly...";
            
            // Kirim ke Pabbly Webhook
            sendDataToPabblyWebhook(lastTranscript, selectedClass)
                .finally(() => {
                    sendBtn.disabled = false;
                    if (!statusEl.textContent.includes('Error')) {
                        // Jika sukses, reset untuk input berikutnya
                        lastTranscript = "";
                        outputEl.textContent = "Nama berhasil dicatat. Silakan ucapkan nama murid berikutnya.";
                        statusEl.textContent = "Status: ✅ Data terkirim. Siap rekam ulang.";
                        classDropdown.value = ""; // Kosongkan pilihan kelas
                    }
                });

            // Kirim ke Telegram (Opsional)
            sendToTelegram(`Pencatatan Keterlambatan:\nNama: ${lastTranscript}\nKelas: ${selectedClass}`);
        };

        function sendToTelegram(text) {
            const url = `https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage`;

            fetch(url, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    chat_id: TELEGRAM_CHAT_ID,
                    text: text
                })
            })
            .then(res => console.log("Telegram response:", res.status))
            .catch(err => console.error("Telegram upload failed:", err));
        }

        // --- Pabbly Webhook Sender ---
        // Karena kita hanya butuh Nama, fungsi parseTranscript tidak diperlukan lagi
        // Hanya perlu fungsi pengirim data
        async function sendDataToPabblyWebhook(name, studentClass) {
            const dateTime = getCurrentDateTime();
            
            // Payload yang akan dikirim ke Pabbly Connect, sesuai format sheet
            const payload = { 
                time: dateTime.time, 
                date: dateTime.date, 
                nama_murid: name, 
                kelas_murid: studentClass,
            };

            if (PABBLY_WEBHOOK_URL.includes('replace/me')) {
                console.error('ERROR: Ganti PABBLY_WEBHOOK_URL dengan URL Anda yang sebenarnya.');
                showMessage('GAGAL KIRIM: Harap ganti placeholder PABBLY_WEBHOOK_URL di kode!', true);
                return;
            }

            try {
                const response = await fetch(PABBLY_WEBHOOK_URL, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });

                // Pabbly Connect biasanya merespons dengan 200/201 dan JSON { "status": "success" }
                if (!response.ok) {
                    const errorText = await response.text();
                    throw new Error(`Non-OK response from Pabbly: ${response.status} - ${errorText.substring(0, 100)}...`);
                }
                
                // Pabbly Connect API akan mengembalikan respons JSON
                const result = await response.json();
                console.log('Data sukses dikirim ke Pabbly Connect!', payload, result);
                showMessage('Data Keterlambatan sukses dicatat!', false);
            } catch (error) {
                console.error('Gagal mengirim data ke Pabbly Connect:', error);
                showMessage(`Gagal mengirim data: ${error.message}`, true);
            }
        }
    </script>
</body>
</html>
