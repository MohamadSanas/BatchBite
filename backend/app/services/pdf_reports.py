from datetime import datetime, timezone
from io import BytesIO

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.models import Order


def _styles():
    return getSampleStyleSheet()


def build_order_summary_pdf(order: Order) -> bytes:
    buf = BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=letter, title=f"Order {order.id}")
    story = []
    styles = _styles()
    story.append(Paragraph(f"Order #{order.id}", styles["Title"]))
    story.append(Spacer(1, 12))
    loc_name = order.delivery_location.name if order.delivery_location else ""
    story.append(Paragraph(f"Status: {order.status.value}", styles["Normal"]))
    story.append(Paragraph(f"Delivery: {loc_name}", styles["Normal"]))
    story.append(Paragraph(f"Deadline: {order.deadline_time.isoformat()}", styles["Normal"]))
    story.append(Spacer(1, 12))
    data = [["Item", "Qty", "Unit", "Line"]]
    total = 0.0
    for oi in order.items:
        fi = oi.food_item
        line = fi.price * oi.quantity
        total += line
        data.append([fi.name, str(oi.quantity), f"{fi.price:.2f}", f"{line:.2f}"])
    data.append(["", "", "Total", f"{total:.2f}"])
    t = Table(data)
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.lightgrey),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ]
        )
    )
    story.append(t)
    doc.build(story)
    return buf.getvalue()


def build_sales_report_pdf(title: str, rows: list[tuple[str, float]], totals: dict[str, float]) -> bytes:
    buf = BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=letter, title=title)
    story = []
    styles = _styles()
    story.append(Paragraph(title, styles["Title"]))
    story.append(Paragraph(f"Generated: {datetime.now(timezone.utc).isoformat()}", styles["Normal"]))
    story.append(Spacer(1, 12))
    data = [["Label", "Amount"]] + [[a, f"{b:.2f}"] for a, b in rows]
    t = Table(data)
    t.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), colors.lightgrey), ("GRID", (0, 0), (-1, -1), 0.5, colors.grey)]))
    story.append(t)
    story.append(Spacer(1, 12))
    story.append(Paragraph(f"Grand total: {totals.get('total', 0):.2f}", styles["Heading3"]))
    story.append(Paragraph(f"Profit: {totals.get('profit', 0):.2f}", styles["Heading3"]))
    doc.build(story)
    return buf.getvalue()
