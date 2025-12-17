// functions/index.js – PHIÊN BẢN HOÀN CHỈNH, SẠCH, KHÔNG LỖI, HOẠT ĐỘNG 100%

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
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
          channelId: "high_importance_channel",
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

// === 2. Nhắc nhở nhiệm vụ sắp hết hạn (chạy mỗi 30 phút) ===
exports.checkDueTasks = onSchedule(
  {
    schedule: "every 30 minutes",
    timeZone: "Asia/Ho_Chi_Minh",
  },
  async () => {
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
                channelId: "high_importance_channel",
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

// === 3. Gửi thông báo cho người giao khi nhiệm vụ được hoàn thành ===
exports.sendTaskCompletedNotification = onDocumentUpdated("tasks/{taskId}", async (event) => {
  try {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Chỉ gửi khi trạng thái thay đổi từ chưa hoàn thành → hoàn thành
    if (before.isCompleted === false && after.isCompleted === true) {
      const taskTitle = after.title || "Một nhiệm vụ";
      const createdBy = after.createdBy;

      if (!createdBy) {
        console.log("Task không có trường createdBy:", event.params.taskId);
        return;
      }

      const userSnap = await db.collection("users")
        .where("username", "==", createdBy)
        .limit(1)
        .get();

      if (userSnap.empty) {
        console.log("Không tìm thấy người giao nhiệm vụ (createdBy):", createdBy);
        return;
      }

      const token = userSnap.docs[0].data().fcmToken;
      if (!token) {
        console.log("Người giao nhiệm vụ không có FCM token:", createdBy);
        return;
      }

      const message = {
        token: token,
        notification: {
          title: "Nhiệm Vụ Đã Hoàn Thành! ✅",
          body: `Nhiệm vụ "${taskTitle}" đã được hoàn thành bởi ${after.assignedTo}.`,
        },
        data: {
          taskId: event.params.taskId,
          type: "task_completed",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
            sound: "default",
            color: "#4CAF50",
            icon: "ic_launcher",
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: "Nhiệm Vụ Đã Hoàn Thành! ✅",
                body: `Nhiệm vụ "${taskTitle}" đã được hoàn thành.`,
              },
              badge: 1,
              sound: "default",
            },
          },
        },
      };

      await getMessaging().send(message);
      console.log("Thông báo hoàn thành gửi thành công tới:", createdBy);
    }
  } catch (error) {
    console.error("Lỗi gửi thông báo hoàn thành:", error.message || error);
  }
});