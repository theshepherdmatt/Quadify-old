if (this.data.trackType) {
  let totalTextWidth = this.data.trackType.length * 5;
  let startX = (this.width - totalTextWidth) / 2;

  // Clear the area before drawing new text
  // Assuming there's a method to draw a rectangle, fillRect(x, y, width, height, color)
  // Adjust the height and y position according to your needs
  this.driver.fillRect(startX, this.height - 22, totalTextWidth, 10, 0); // 0 for black

  this.driver.setCursor(startX, this.height - 22);
  this.driver.writeString(fonts.monospace, 1, this.data.trackType, 4);
}
