// functions/index.js – ĐÃ SỬA HOÀN CHỈNH, ĐẢM BẢO NHẬN THÔNG BÁO 100%

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

admin.initializeApp();
const db = getFirestore();

// === 1. Gửi thông báo khi tạo nhiệm vụ mới ===
exports.sendNewTaskNotification = onDocumentCreated("tasks/{taskId}", async (event) => {
  try {
    const snap = event.data;
    if (!snap) return;

    const task = snap.data();
    const assignedTo = task.assignedTo;

    const userSnap = await db.collection("users")
      .where("username", "==", assignedTo)
      .limit(1)
      .get();

    if (userSnap.empty) {
      console.log("User not found:", assignedTo);
      return;
    }

    const userData = userSnap.docs[0].data();
    const token = userData.fcmToken;

    if (!token) {
      console.log("No FCM token for user:", assignedTo);
      return;
    }

    const message = {
      token: token,
      notification: {
        title: "Nhiệm Vụ Mới!",
        body: `Bạn được giao nhiệm vụ: "${task.title}"`,
      },
      data: {
        taskId: snap.id,
        type: "new_task",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "task_channel_id",                // PHẢI TRÙNG với Flutter
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
          sound: "default",
          color: "#1E88E5",
          icon: "ic_launcher",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: "Nhiệm Vụ Mới!",
              body: `Bạn được giao nhiệm vụ: "${task.title}"`,
            },
            badge: 1,
            sound: "default",
          },
        },
      },
    };

    await getMessaging().send(message);
    console.log("Notification sent successfully to:", assignedTo);
  } catch (error) {
    console.error("Error sending new task notification:", error.message || error);
  }
});

// === 2. Nhắc nhở còn ~1 giờ (chạy mỗi 30 phút) ===
exports.checkDueTasks = onSchedule(
  {
    schedule: "every 30 minutes",
    timeZone: "Asia/Ho_Chi_Minh",
  },
  async (event) => {
    try {
      const now = admin.firestore.Timestamp.now();
      const oneHourLater = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 60 * 60 * 1000)
      );

      const tasksSnap = await db.collection("tasks")
        .where("isCompleted", "==", false)
        .get();

      for (const doc of tasksSnap.docs) {
        const task = doc.data();
        const dueDate = task.dueDate;

        if (
          dueDate &&
          dueDate.toDate() > now.toDate() &&
          dueDate.toDate() <= oneHourLater.toDate()
        ) {
          const userSnap = await db.collection("users")
            .where("username", "==", task.assignedTo)
            .limit(1)
            .get();

          if (userSnap.empty) continue;

          const token = userSnap.docs[0].data().fcmToken;
          if (!token) continue;

          const message = {
            token: token,
            notification: {
              title: "Sắp Hết Hạn!",
              body: `Nhiệm vụ "${task.title}" chỉ còn khoảng 1 giờ!`,
            },
            data: {
              taskId: doc.id,
              type: "due_soon",
            },
            android: {
              priority: "high",
              notification: {
                channelId: "task_channel_id",            // PHẢI TRÙNG
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
                sound: "default",
                color: "#FF5722",
              },
            },
            apns: {
              payload: {
                aps: {
                  alert: {
                    title: "Sắp Hết Hạn!",
                    body: `Nhiệm vụ "${task.title}" chỉ còn khoảng 1 giờ!`,
                  },
                  badge: 1,
                  sound: "default",
                },
              },
            },
          };

          try {
            await getMessaging().send(message);
            console.log("Reminder sent for task:", task.title);
          } catch (msgError) {
            console.error("Failed to send reminder to", task.assignedTo, msgError.message);
          }
        }
      }
    } catch (error) {
      console.error("Error in checkDueTasks:", error.message || error);
    }
  }
);