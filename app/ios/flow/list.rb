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

    def tableView(table_view, cellForRowAtIndexPath: index_path)
      row_klass = @render_row_block.call(index_path.section, index_path.row)
      data = @data_source[index_path.row]
      cell_identifier = CustomListCell::IDENTIFIER + row_klass.name
      cell = table_view.dequeueReusableCellWithIdentifier(cell_identifier)
      unless cell
        row = (@cached_rows[data] ||= row_klass.new)
        row.list = self if row.respond_to?(:list=)
        cell = CustomListCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: cell_identifier)
        cell.selectionStyle = UITableViewCellSelectionStyleNone
        cell.content_view = row
        cell.list = self
      end
      cell.content_view.update(data) if cell.content_view.respond_to?(:update)
      cell.content_view.update_layout
      _set_row_height(index_path, cell.content_view, true)
      cell
    end

    def update_begin
      proxy.beginUpdates
@changed=false
    end

    def update_end
      proxy.endUpdates
if @changed==true
refresh
@changed=false
end
    end

    def insert(x, r, a = {})
      inses = []
      i = @data_source.size - 1
      if i >= x
        @data_source.push("")
        inses.push(NSIndexPath.indexPathForRow(@data_source.size - 1, inSection: 0))
        while i >= x
          @data_source[i + 1] = @data_source[i]
          i -= 1
          actions[i + 1] = actions[i]
        end
      else
        for j in i...x
          @data_source.push("")
          inses.push(NSIndexPath.indexPathForRow(@data_source.size - 1, inSection: 0))
        end
      end
      edit(x, r, a)
      proxy.insertRowsAtIndexPaths(inses, withRowAnimation: UITableViewRowAnimationBottom)
    end

    def edit(x, r, a = [])
      return insert(x, r, a) if x >= @data_source.size
if @data_source[x]!=r or actions[x]!=a
      @data_source[x] = r
      actions[x] = a
@changed=true
end
    end

    def add(r, a = [])
      insert(@data_source.size, r, a)
    end

    def multiadd(r, a = [])
      for i in 0...r.size
        add(r[i], a[i])
      end
    end

def refresh
selectedRows = proxy.indexPathsForSelectedRows
proxy.reloadData
if selectedRows!=nil
for indexPath in selectedRows
proxy.selectRowAt(indexPath, animated: false, scrollPosition: UITableViewScrollPositionNone)
end
end
end

def setFocus
UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, proxy);
end

def on_refresh
trigger(:refresh)
end

def refresh_enable
proxy.refreshControl = UIRefreshControl.alloc.init
proxy.refreshControl.addTarget(self, action: :on_refresh, forControlEvents: UIControlEventValueChanged)
end

def refresh_disable
proxy.refreshControl=nil
end

def refresh_begin
return if proxy.refreshControl==nil
proxy.refreshControl.beginRefreshing
end

def refresh_end
return if proxy.refreshControl==nil
proxy.refreshControl.endRefreshing
end

def refreshing?
return false if proxy.refreshControl==nil
return proxy.refreshControl.isRefreshing
end
  end
end
