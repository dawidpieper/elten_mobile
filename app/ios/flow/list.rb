module UI
  class List < View
    include Eventable

    def actions
      return @actions ||= {}
    end

    def actions=(ac)
      @actions = ac if ac.is_a?(Hash) or ac.is_a?(Array)
    end

    def tableView(table_view, editActionsForRowAtIndexPath: index_path)
      if actions[index_path.row].is_a?(Hash)
        acs = []
        act = actions[index_path.row]
        for ac in act.keys
          acs.push UITableViewRowAction.rowActionWithStyle(UITableViewRowActionStyleDefault, title: ac, handler: act[ac])
        end
        return acs
      else
        return []
      end
    end

    def scroll(index)
      proxy.scrollToRowAtIndexPath(NSIndexPath.indexPathForRow(index, inSection: 0), atScrollPosition: UITableViewScrollPositionMiddle, animated: false)
    end
  end
end
