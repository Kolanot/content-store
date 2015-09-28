module Tasks
  module DataHygiene
    class DuplicateReport
      def full
        summary.blank_content_ids = ContentItem.where(content_id: nil).count
        duplicates = fetch_all_duplicate_content_items
        summary.duplicates = duplicates.count
        write_to_csv(duplicates)
        summarise
      end

      def scoped_to(locale:)
        summary.blank_content_ids = ContentItem.where(content_id: nil).count
        duplicates = fetch_all_duplicate_content_items
        summary.duplicates = duplicates.count

        # Identify duplicate (content_id, locale) tuples
        duplicates.reject! { |ci| ci.locale != locale }
        content_id_counts = count_repeated_content_ids_in(duplicates)
        duplicates_for_locale = content_id_counts.flat_map do |content_id_count|
          ContentItem.where(content_id: content_id_count.first, locale: locale).to_a
        end
        summary.duplicates_for_locale = duplicates_for_locale.count

        write_to_csv(duplicates_for_locale, locale)
        summarise
      end

private
      def summary
        @summary ||= OpenStruct.new
      end

      def fetch_all_duplicate_content_items(exclude_null_content_id: true)
        puts "Fetching content items for duplicated content ids..."
        duplicate_content_id_aggregation.flat_map do |content_id_count|
          next if content_id_count["_id"].blank? && exclude_null_content_id
          ContentItem.where(content_id: content_id_count["_id"]).to_a
        end.compact
      end

      def duplicate_content_id_aggregation
        @duplicate_content_id_aggregation ||= ContentItem.collection.aggregate([
          {
            "$group" => {
              "_id" => "$content_id", "count" => {"$sum" => 1}
            }
          },
          {
            "$match" => { "count" => {"$gt" => 1} }
          }
        ])
      end

      def count_repeated_content_ids_in(content_items)
        # Produce a hash of the form { "myC00lc0ntentID" => 3 }"
        content_items.each_with_object(Hash.new(0)) do |ci, hash|
          hash[ci.content_id] += 1
        end.select! { |k, v| v > 1 }
      end

      def summarise
        puts "~~~~~~~~~\n Summary \n~~~~~~~~~\n"
        summary.each_pair do |attr, val|
          puts "#{attr}: #{val}"
        end
      end

      def write_to_csv(content_items, locale=nil)
        puts "Writing content items to csv..."
        current_time = Time.now.strftime("%Y-%m-%d-%H-%M")
        filename = "duplicate_content_ids_#{current_time}"
        filename = "#{locale}_#{filename}" if locale

        CSV.open("tmp/#{filename}.csv", 'wb') do |csv|
          content_item_fields = [
            "_id", "content_id", "title", "format", "locale", "publishing_app",
            "rendering_app", "routes", "redirects", "phase", "analytics_identifier",
            "updated_at"
          ]

          csv << content_item_fields
          content_items.each do |content_item|
            csv << content_item_fields.map do |field|
              content_item.send("#{field}")
            end
          end
        end
      end
    end
  end
end