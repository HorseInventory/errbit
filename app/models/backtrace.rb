class Backtrace
  include Mongoid::Document
  include Mongoid::Timestamps

  IN_APP_PATH = %r{^(?:\[|/)PROJECT_ROOT\]?(?!(/vendor))/?}
  GEMS_PATH = %r{(?:\[|/)GEM_ROOT\]?/gems/([^/]+)}

  field :fingerprint
  field :lines

  index fingerprint: 1

  before_validation :ensure_fingerprint
  validates :lines, :fingerprint, presence: true

  def self.find_or_create(lines)
    fingerprint = generate_fingerprint(lines)

    where(fingerprint: fingerprint).find_one_and_update(
      { '$setOnInsert' => { fingerprint: fingerprint, lines: lines } },
      return_document: :after,
      upsert: true)
  end

  def self.find_or_build(lines)
    fingerprint = generate_fingerprint(lines)

    backtrace = where(fingerprint: fingerprint).first

    unless backtrace
      backtrace = new(lines: lines)
      backtrace.ensure_fingerprint
    end

    backtrace
  end

  def ensure_fingerprint
    self.fingerprint ||= self.class.generate_fingerprint(lines)
  end

  def self.generate_fingerprint(lines)
    Digest::SHA1.hexdigest(lines.map(&:to_s).join)
  end

private

  def generate_fingerprint
    self.fingerprint = self.class.generate_fingerprint(lines)
  end
end
