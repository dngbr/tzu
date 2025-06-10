require "rqrcode"

module ApplicationHelper
  # Generate a URL for an image stored in the S3 bucket
  def s3_image_url(image_name)
    "https://#{ENV['S3_BUCKET']}.s3.amazonaws.com/#{image_name}"
  end

  # Generate HTML for a circular icon
  def circular_icon(image_name, size: 32, classes: "")
    image_tag(s3_image_url(image_name),
              class: "rounded-full object-cover #{classes}",
              style: "width: #{size}px; height: #{size}px;",
              alt: "Icon")
  end

  # Generate a QR code for a URL
  def generate_qr_code(url, size: 8)
    qrcode = RQRCode::QRCode.new(url)

    svg = qrcode.as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: size,
      standalone: true,
      use_path: true
    )

    svg.html_safe
  end
end
